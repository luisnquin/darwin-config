import AppKit

func shell(_ launchPath: String, _ arguments: [String], background: Bool = false) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = arguments
    // Background QoS opts the child into darwin's I/O throttling, so a du walk
    // over /nix/store cannot starve foreground work.
    process.qualityOfService = background ? .background : .userInitiated
    let stdout = Pipe()
    process.standardOutput = stdout
    process.standardError = FileHandle.nullDevice
    do { try process.run() } catch { return nil }
    let data = stdout.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return String(data: data, encoding: .utf8)
}

struct DiskInfo {
    let free: Int64
    let total: Int64
    let purgeable: Int64

    static func current() -> DiskInfo? {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        guard
            let values = try? url.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeAvailableCapacityKey,
                .volumeTotalCapacityKey,
            ]),
            let important = values.volumeAvailableCapacityForImportantUsage,
            let strict = values.volumeAvailableCapacity,
            let total = values.volumeTotalCapacity
        else { return nil }
        return DiskInfo(
            free: important,
            total: Int64(total),
            purgeable: max(0, important - Int64(strict))
        )
    }
}

extension RuntimeStatus {
    static func detect() -> RuntimeStatus {
        var status = RuntimeStatus()
        status.xcodeRunning = NSWorkspace.shared.runningApplications
            .contains { $0.bundleIdentifier == "com.apple.dt.Xcode" }
        status.simulatorsBooted = shell(
            "/usr/bin/xcrun", ["simctl", "list", "devices", "booted"]
        )?.contains("(Booted)") ?? false
        status.androidEmulatorRunning = shell(
            "/usr/bin/pgrep", ["-f", "qemu-system|emulator.*-avd"]
        ).map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false
        return status
    }
}

final class Scanner {
    private static let scanMaxAge: TimeInterval = 6 * 60 * 60
    private static let cacheSizesKey = "scanSizes"
    private static let cacheDateKey = "scanDate"

    private let queue = DispatchQueue(label: "roomy.scan", qos: .background)
    private(set) var results: [Measurement] = []
    private(set) var scanning = false
    private(set) var lastScan: Date?
    var onUpdate: (() -> Void)?

    init() {
        // A du walk over /nix/store is minutes of I/O; surviving app restarts
        // on cached numbers keeps relaunches free.
        let defaults = UserDefaults.standard
        guard
            let sizes = defaults.dictionary(forKey: Self.cacheSizesKey) as? [String: Int64],
            let date = defaults.object(forKey: Self.cacheDateKey) as? Date
        else { return }
        results = candidates.compactMap { candidate in
            sizes[candidate.path].map { Measurement(candidate: candidate, size: $0) }
        }.sorted { $0.size > $1.size }
        lastScan = date
    }

    func scanIfStale() {
        if scanning { return }
        if let last = lastScan, Date().timeIntervalSince(last) < Self.scanMaxAge { return }
        scan()
    }

    func scan() {
        if scanning { return }
        scanning = true
        onUpdate?()
        queue.async {
            var measured: [Measurement] = []
            for candidate in candidates {
                guard FileManager.default.fileExists(atPath: candidate.path) else { continue }
                guard
                    let output = shell("/usr/bin/du", ["-sk", candidate.path], background: true),
                    let size = parseDuOutput(output)
                else { continue }
                measured.append(Measurement(candidate: candidate, size: size))
            }
            measured.sort { $0.size > $1.size }
            DispatchQueue.main.async {
                self.results = measured
                self.scanning = false
                self.lastScan = Date()
                let defaults = UserDefaults.standard
                defaults.set(
                    Dictionary(uniqueKeysWithValues: measured.map { ($0.candidate.path, $0.size) }),
                    forKey: Self.cacheSizesKey)
                defaults.set(self.lastScan, forKey: Self.cacheDateKey)
                self.onUpdate?()
            }
        }
    }
}

// MARK: - UI helpers

func tintColor(_ name: String) -> NSColor {
    switch name {
    case "blue": return .systemBlue
    case "orange": return .systemOrange
    case "purple": return .systemPurple
    case "teal": return .systemTeal
    case "indigo": return .systemIndigo
    case "brown": return .systemBrown
    case "green": return .systemGreen
    case "cyan": return .systemCyan
    case "yellow": return .systemYellow
    case "red": return .systemRed
    default: return .secondaryLabelColor
    }
}

func symbolImage(_ name: String, color: NSColor, pointSize: CGFloat = 14) -> NSImage? {
    guard
        let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
    else { return nil }
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
    let image = base.withSymbolConfiguration(config)
    // Template images get flattened to monochrome inside menus; clearing the
    // flag keeps the palette tint.
    image?.isTemplate = false
    return image
}

func label(
    _ text: String, font: NSFont, color: NSColor = .labelColor
) -> NSTextField {
    let field = NSTextField(labelWithString: text)
    field.font = font
    field.textColor = color
    field.lineBreakMode = .byTruncatingTail
    return field
}

final class CapacityBar: NSView {
    var fraction: Double = 0
    var color: NSColor = .systemGreen

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 6)
    }

    override func draw(_: NSRect) {
        let radius = bounds.height / 2
        NSColor.quaternaryLabelColor.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius).fill()
        let width = bounds.width * CGFloat(min(max(fraction, 0), 1))
        guard width > bounds.height else { return }
        color.setFill()
        NSBezierPath(
            roundedRect: NSRect(x: 0, y: 0, width: width, height: bounds.height),
            xRadius: radius, yRadius: radius
        ).fill()
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let menuWidth: CGFloat = 300

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let scanner = Scanner()
    private var status = RuntimeStatus()
    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu.delegate = self
        statusItem.menu = menu

        scanner.onUpdate = { [weak self] in self?.rebuildMenu() }
        updateTitle()
        refreshStatus()
        scanner.scanIfStale()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTitle()
            self?.scanner.scanIfStale()
        }
    }

    func menuWillOpen(_: NSMenu) {
        updateTitle()
        rebuildMenu()
        refreshStatus()
        scanner.scanIfStale()
    }

    private func refreshStatus() {
        DispatchQueue.global(qos: .userInitiated).async {
            let detected = RuntimeStatus.detect()
            DispatchQueue.main.async {
                self.status = detected
                self.rebuildMenu()
            }
        }
    }

    private func updateTitle() {
        guard let info = DiskInfo.current(), let button = statusItem.button else { return }
        let color: NSColor
        switch freeSpaceLevel(free: info.free, total: info.total) {
        case .critical: color = .systemRed
        case .low: color = .systemOrange
        case .normal: color = .controlTextColor
        }
        button.attributedTitle = NSAttributedString(
            string: compact(info.free),
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: color,
            ])
        button.toolTip = "Free: \(format(info.free)) of \(format(info.total))"
    }

    // MARK: Header panel

    private func makeHeaderView() -> NSView {
        let container = NSView()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 5
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: Self.menuWidth),
        ])

        func fillWidth(_ view: NSView) {
            stack.addArrangedSubview(view)
            view.trailingAnchor.constraint(
                equalTo: stack.trailingAnchor, constant: -stack.edgeInsets.right
            ).isActive = true
        }

        // Title row: app name + rescan button.
        let titleRow = NSStackView()
        titleRow.orientation = .horizontal
        titleRow.addArrangedSubview(
            label("Roomy", font: .boldSystemFont(ofSize: 13)))
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleRow.addArrangedSubview(spacer)
        if let icon = symbolImage("arrow.clockwise", color: .secondaryLabelColor, pointSize: 12) {
            let rescanButton = NSButton(image: icon, target: self, action: #selector(rescan(_:)))
            rescanButton.isBordered = false
            rescanButton.toolTip = "Rescan now"
            titleRow.addArrangedSubview(rescanButton)
        }
        fillWidth(titleRow)

        guard let info = DiskInfo.current() else {
            container.layoutSubtreeIfNeeded()
            container.frame = NSRect(
                x: 0, y: 0, width: Self.menuWidth, height: container.fittingSize.height)
            return container
        }

        let level = freeSpaceLevel(free: info.free, total: info.total)

        // Big free number.
        let big = NSMutableAttributedString(
            string: format(info.free),
            attributes: [.font: NSFont.systemFont(ofSize: 24, weight: .bold)])
        big.append(NSAttributedString(
            string: "  free",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]))
        let bigLabel = NSTextField(labelWithAttributedString: big)
        stack.addArrangedSubview(bigLabel)

        let percent = Int(Double(info.free) / Double(info.total) * 100)
        var subText = "of \(format(info.total)) · \(percent)% available"
        if info.purgeable > gigabyte {
            subText += " · \(format(info.purgeable)) purgeable"
        }
        stack.addArrangedSubview(
            label(subText, font: .systemFont(ofSize: 11), color: .secondaryLabelColor))

        // Capacity bar shows *used* space, tinted by how tight things are.
        let bar = CapacityBar()
        bar.fraction = 1 - Double(info.free) / Double(info.total)
        switch level {
        case .critical: bar.color = .systemRed
        case .low: bar.color = .systemOrange
        case .normal: bar.color = .systemGreen
        }
        bar.translatesAutoresizingMaskIntoConstraints = false
        fillWidth(bar)

        let statusText: String
        switch level {
        case .critical: statusText = "Storage is critically low"
        case .low: statusText = "Storage is getting tight"
        case .normal: statusText = "Plenty of breathing room"
        }
        let dot = NSMutableAttributedString(
            string: "● ",
            attributes: [.font: NSFont.systemFont(ofSize: 9), .foregroundColor: bar.color])
        dot.append(NSAttributedString(
            string: statusText,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]))
        stack.addArrangedSubview(NSTextField(labelWithAttributedString: dot))

        // Reclaimable summary from the scan, split by what is safe right now.
        let totals = reclaimable(from: scanner.results, status: status)
        if totals.safeNow > gigabyte || totals.gated > gigabyte {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 6
            let reclaimTint: NSColor = totals.safeNow > gigabyte ? .systemGreen : .systemOrange
            if let recycle = symbolImage("arrow.3.trianglepath", color: reclaimTint, pointSize: 14) {
                row.addArrangedSubview(NSImageView(image: recycle))
            }
            let column = NSStackView()
            column.orientation = .vertical
            column.alignment = .leading
            column.spacing = 1
            let headline = totals.safeNow > gigabyte
                ? "~\(format(totals.safeNow)) reclaimable"
                : "~\(format(totals.gated)) reclaimable later"
            column.addArrangedSubview(
                label(headline, font: .systemFont(ofSize: 12, weight: .semibold)))
            var detail = totals.safeNow > gigabyte
                ? "Safe to clean now — see each item below"
                : "Blocked while simulators or emulators run"
            if totals.safeNow > gigabyte, totals.gated > gigabyte {
                detail = "Safe now · ~\(format(totals.gated)) more after closing apps"
            }
            column.addArrangedSubview(
                label(detail, font: .systemFont(ofSize: 10), color: .secondaryLabelColor))
            row.addArrangedSubview(column)
            stack.addArrangedSubview(row)
        }

        container.layoutSubtreeIfNeeded()
        container.frame = NSRect(
            x: 0, y: 0, width: Self.menuWidth, height: container.fittingSize.height)
        return container
    }

    // MARK: Menu

    private func rebuildMenu() {
        menu.removeAllItems()

        let headerItem = NSMenuItem()
        headerItem.view = makeHeaderView()
        menu.addItem(headerItem)

        menu.addItem(.separator())
        menu.addItem(sectionHeader(
            scanner.scanning ? "Measuring…" : "Largest storage consumers"))

        for measurement in scanner.results.prefix(8) where measurement.size > gigabyte / 2 {
            menu.addItem(consumerItem(for: measurement))
        }

        menu.addItem(.separator())
        if scanner.scanning {
            menu.addItem(sectionHeader("Scanning…"))
        } else if let last = scanner.lastScan {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            menu.addItem(sectionHeader(
                "Last scan \(formatter.localizedString(for: last, relativeTo: Date()))"))
        }
        let rescan = NSMenuItem(title: "Rescan", action: #selector(rescan(_:)), keyEquivalent: "r")
        rescan.target = self
        menu.addItem(rescan)
        menu.addItem(NSMenuItem(
            title: "Quit Roomy", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func consumerItem(for measurement: Measurement) -> NSMenuItem {
        let candidate = measurement.candidate

        // "label <tab> size" with a right-aligned tab stop, sublabel underneath.
        let style = NSMutableParagraphStyle()
        style.tabStops = [NSTextTab(textAlignment: .right, location: 225, options: [:])]
        style.lineBreakMode = .byTruncatingTail
        let title = NSMutableAttributedString(
            string: "\(candidate.label)\t\(format(measurement.size))\n",
            attributes: [
                .font: NSFont.menuFont(ofSize: 13),
                .paragraphStyle: style,
            ])
        title.append(NSAttributedString(
            string: candidate.sublabel,
            attributes: [
                .font: NSFont.menuFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: style,
            ]))

        let item = NSMenuItem(title: candidate.label, action: nil, keyEquivalent: "")
        item.attributedTitle = title
        item.image = symbolImage(candidate.symbol, color: tintColor(candidate.tint))
        item.toolTip = candidate.path

        let submenu = NSMenu()
        let reveal = NSMenuItem(
            title: "Reveal in Finder", action: #selector(revealInFinder(_:)), keyEquivalent: "")
        reveal.target = self
        reveal.representedObject = candidate.path
        submenu.addItem(reveal)

        if let tip = candidate.tip, let command = candidate.tipCommand {
            submenu.addItem(.separator())
            let blocked = status.blocks(candidate.gate)
            var statusText = "\(tip) — safe now"
            if blocked, let gate = candidate.gate {
                statusText = "\(tip) — wait, \(gate.reason)"
            }
            let statusLine = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
            statusLine.image = symbolImage(
                blocked ? "exclamationmark.triangle" : "checkmark.circle",
                color: blocked ? .systemOrange : .systemGreen,
                pointSize: 12)
            submenu.addItem(statusLine)

            let copy = NSMenuItem(
                title: "Copy cleanup command", action: #selector(copyCommand(_:)),
                keyEquivalent: "")
            copy.target = self
            copy.representedObject = command
            copy.toolTip = command
            submenu.addItem(copy)
        }
        item.submenu = submenu
        return item
    }

    private func sectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func revealInFinder(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }

    @objc private func copyCommand(_ sender: NSMenuItem) {
        guard let command = sender.representedObject as? String else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(command, forType: .string)
    }

    @objc private func rescan(_: Any?) {
        scanner.scan()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
