import AppKit

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
        // Sizes are cached, the drive each path sits on is not: an unplugged
        // volume takes its rows with it rather than reattributing them.
        results = candidates.compactMap { candidate in
            guard
                let size = sizes[candidate.path],
                FileManager.default.fileExists(atPath: candidate.path)
            else { return nil }
            return Measurement(
                candidate: candidate, size: size,
                volume: volumeIdentifier(ofPath: candidate.path))
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
                measured.append(Measurement(
                    candidate: candidate, size: size,
                    volume: volumeIdentifier(ofPath: candidate.path)))
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
    case "pink": return .systemPink
    case "mint": return .systemMint
    default: return .secondaryLabelColor
    }
}

// The bar and the dot always carry the traffic light; the menu bar title keeps
// the normal state neutral so a healthy drive is not a green distraction.
func levelTint(_ level: FreeSpaceLevel) -> NSColor {
    switch level {
    case .critical: return .systemRed
    case .low: return .systemOrange
    case .normal: return .systemGreen
    }
}

func levelSummary(_ level: FreeSpaceLevel) -> String {
    switch level {
    case .critical: return "Critically low"
    case .low: return "Getting tight"
    case .normal: return "Plenty of room"
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

    private func currentReports() -> [VolumeReport] {
        buildReports(
            volumes: discoverVolumes(),
            usage: { DiskUsage.current(mountPoint: $0.mountPoint) },
            measurements: scanner.results,
            status: status)
    }

    // MARK: Status bar title

    // One drive-icon-and-number pair per drive, so the two SSDs are told apart
    // in the menu bar itself rather than only once the menu is open.
    private func updateTitle() {
        guard let button = statusItem.button else { return }
        let reports = currentReports()
        let title = NSMutableAttributedString()
        var tooltip: [String] = []

        for report in reports {
            if title.length > 0 {
                title.append(NSAttributedString(
                    string: "  ", attributes: [.font: NSFont.systemFont(ofSize: 12)]))
            }
            let level = report.usage.level
            let color: NSColor = level == .normal ? .controlTextColor : levelTint(level)
            if let icon = symbolImage(report.volume.symbol, color: color, pointSize: 11) {
                let attachment = NSTextAttachment()
                attachment.image = icon
                // Attachments sit on the text baseline by their bottom edge;
                // the nudge centres the glyph against the digits beside it.
                attachment.bounds = NSRect(
                    x: 0, y: -2.5, width: icon.size.width, height: icon.size.height)
                title.append(NSAttributedString(attachment: attachment))
                title.append(NSAttributedString(string: " "))
            }
            title.append(NSAttributedString(
                string: compact(report.usage.free),
                attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: color,
                ]))
            tooltip.append(
                "\(report.volume.name) (\(report.volume.kind.lowercased())): "
                    + "\(format(report.usage.free)) free of \(format(report.usage.total))")
        }

        if title.length == 0 { return }
        button.attributedTitle = title
        button.toolTip = tooltip.joined(separator: "\n")
    }

    // MARK: Panels

    // Shared chrome for the menu's view-backed rows: a fixed-width column with
    // the menu's own insets, sized to whatever gets stacked into it.
    private func panel(_ build: (NSStackView, (NSView) -> Void) -> Void) -> NSView {
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

        build(stack, fillWidth)

        container.layoutSubtreeIfNeeded()
        container.frame = NSRect(
            x: 0, y: 0, width: Self.menuWidth, height: container.fittingSize.height)
        return container
    }

    private func makeTitleRow() -> NSView {
        panel { _, fillWidth in
            let row = NSStackView()
            row.orientation = .horizontal
            row.addArrangedSubview(label("Roomy", font: .boldSystemFont(ofSize: 13)))
            let spacer = NSView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            row.addArrangedSubview(spacer)
            if let icon = symbolImage("arrow.clockwise", color: .secondaryLabelColor, pointSize: 12) {
                let rescanButton = NSButton(image: icon, target: self, action: #selector(rescan(_:)))
                rescanButton.isBordered = false
                rescanButton.toolTip = "Rescan now"
                row.addArrangedSubview(rescanButton)
            }
            fillWidth(row)
        }
    }

    // One card per drive. Name, bus and icon lead so the two drives are never
    // confused for one another; the numbers under them all belong to that card.
    private func makeDriveCard(for report: VolumeReport) -> NSView {
        panel { stack, fillWidth in
            let usage = report.usage
            let level = usage.level
            let tint = levelTint(level)

            let nameRow = NSStackView()
            nameRow.orientation = .horizontal
            nameRow.spacing = 5
            if let icon = symbolImage(report.volume.symbol, color: tint, pointSize: 13) {
                nameRow.addArrangedSubview(NSImageView(image: icon))
            }
            nameRow.addArrangedSubview(
                label(report.volume.name, font: .systemFont(ofSize: 12, weight: .semibold)))
            let spacer = NSView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            nameRow.addArrangedSubview(spacer)
            nameRow.addArrangedSubview(label(
                "\(report.volume.kind) · \(report.volume.mountPoint)",
                font: .systemFont(ofSize: 10), color: .tertiaryLabelColor))
            fillWidth(nameRow)

            let big = NSMutableAttributedString(
                string: format(usage.free),
                attributes: [.font: NSFont.systemFont(ofSize: 22, weight: .bold)])
            big.append(NSAttributedString(
                string: "  free",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor.secondaryLabelColor,
                ]))
            stack.addArrangedSubview(NSTextField(labelWithAttributedString: big))

            var subText = "of \(format(usage.total)) · \(usage.freePercent)% available"
            if usage.purgeable > gigabyte {
                subText += " · \(format(usage.purgeable)) purgeable"
            }
            stack.addArrangedSubview(
                label(subText, font: .systemFont(ofSize: 11), color: .secondaryLabelColor))

            // The bar shows *used* space, tinted by how tight things are.
            let bar = CapacityBar()
            bar.fraction = usage.usedFraction
            bar.color = tint
            bar.translatesAutoresizingMaskIntoConstraints = false
            fillWidth(bar)

            let dot = NSMutableAttributedString(
                string: "● ",
                attributes: [.font: NSFont.systemFont(ofSize: 9), .foregroundColor: tint])
            dot.append(NSAttributedString(
                string: levelSummary(level),
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.secondaryLabelColor,
                ]))
            stack.addArrangedSubview(NSTextField(labelWithAttributedString: dot))

            // Reclaimable summary from the scan, split by what is safe right now.
            let totals = report.reclaimable
            guard totals.safeNow > gigabyte || totals.gated > gigabyte else { return }
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
    }

    // MARK: Menu

    private func rebuildMenu() {
        menu.removeAllItems()

        let titleItem = NSMenuItem()
        titleItem.view = makeTitleRow()
        menu.addItem(titleItem)

        let reports = currentReports()
        for report in reports {
            menu.addItem(.separator())
            let card = NSMenuItem()
            card.view = makeDriveCard(for: report)
            menu.addItem(card)
        }

        // Consumers stay under the drive they fill: one flat list would leave
        // every row having to name its own disk.
        var listed = false
        for report in reports {
            let rows = report.measurements
                .filter { $0.size > gigabyte / 2 }
                .prefix(5)
            guard !rows.isEmpty else { continue }
            listed = true
            menu.addItem(.separator())
            menu.addItem(sectionHeader(
                reports.count > 1
                    ? "Largest on \(report.volume.name)"
                    : "Largest storage consumers"))
            for measurement in rows {
                menu.addItem(consumerItem(for: measurement))
            }
        }
        if !listed {
            menu.addItem(.separator())
            menu.addItem(sectionHeader(scanner.scanning ? "Measuring…" : "Nothing large to list"))
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
