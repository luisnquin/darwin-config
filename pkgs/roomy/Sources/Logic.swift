import Foundation

let gigabyte: Int64 = 1_000_000_000

func format(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}

func compact(_ bytes: Int64) -> String {
    let gb = Double(bytes) / Double(gigabyte)
    return gb >= 10 ? String(format: "%.0fG", gb) : String(format: "%.1fG", gb)
}

// `du -sk` prints "<kilobytes>\t<path>".
func parseDuOutput(_ output: String) -> Int64? {
    guard
        let field = output.split(separator: "\t").first,
        let kilobytes = Int64(field.trimmingCharacters(in: .whitespaces))
    else { return nil }
    return kilobytes * 1024
}

enum FreeSpaceLevel {
    case normal
    case low
    case critical
}

func freeSpaceLevel(free: Int64, total: Int64) -> FreeSpaceLevel {
    if free < 8 * gigabyte { return .critical }
    if free < max(15 * gigabyte, total / 10) { return .low }
    return .normal
}

// What makes a cleanup unsafe right now. Checked live so a tip is offered as
// "safe now" only when nothing depends on the files it would delete.
enum Gate {
    case simulatorsBooted
    case androidEmulatorRunning
    case xcodeRunning

    var reason: String {
        switch self {
        case .simulatorsBooted: return "simulator booted"
        case .androidEmulatorRunning: return "emulator running"
        case .xcodeRunning: return "Xcode open"
        }
    }
}

struct RuntimeStatus {
    var simulatorsBooted = false
    var androidEmulatorRunning = false
    var xcodeRunning = false

    func blocks(_ gate: Gate?) -> Bool {
        switch gate {
        case .simulatorsBooted: return simulatorsBooted
        case .androidEmulatorRunning: return androidEmulatorRunning
        case .xcodeRunning: return xcodeRunning
        case nil: return false
        }
    }
}

struct Candidate {
    let path: String
    let label: String
    // One-liner under the label in the menu row: what actually holds the space.
    let sublabel: String
    // SF Symbol name and a tint keyword resolved to an NSColor by the UI layer;
    // kept as strings so this file stays AppKit-free and testable.
    let symbol: String
    let tint: String
    let tip: String?
    let tipCommand: String?
    let threshold: Int64
    let gate: Gate?
}

let home = NSHomeDirectory()

// Emulator-safe on purpose: AVDs in ~/.android/avd are never deletion targets,
// `simctl delete unavailable` only removes devices whose runtime is already
// gone, and anything a live emulator/simulator/Xcode could depend on is gated
// behind a runtime check. TCC-protected folders (Downloads, Trash, Desktop,
// Documents) are excluded: the ad-hoc signature changes every rebuild, so
// macOS would re-prompt for them after every darwin-rebuild switch.
let candidates: [Candidate] = [
    Candidate(
        path: "/nix/store", label: "Nix store",
        sublabel: "Old generations", symbol: "shippingbox", tint: "blue",
        tip: "Trim old generations",
        // roomy-gc sweeps dead .app store paths first; plain nix-collect-garbage
        // aborts on them (TCC denies the chmod nix does before unlinking).
        tipCommand: "sudo roomy-gc",
        threshold: 15 * gigabyte, gate: nil),
    Candidate(
        path: "\(home)/Library/Developer/Xcode/DerivedData", label: "Xcode DerivedData",
        sublabel: "Build data, Xcode rebuilds it", symbol: "hammer", tint: "orange",
        tip: "Safe to wipe, Xcode rebuilds it",
        tipCommand: "rm -rf ~/Library/Developer/Xcode/DerivedData",
        threshold: 5 * gigabyte, gate: .xcodeRunning),
    Candidate(
        path: "\(home)/Library/Developer/CoreSimulator", label: "iOS simulators",
        sublabel: "Runtimes and devices", symbol: "iphone", tint: "purple",
        tip: "Drop simulators with no runtime",
        tipCommand: "xcrun simctl delete unavailable",
        threshold: 10 * gigabyte, gate: nil),
    Candidate(
        path: "\(home)/Library/Developer/CoreSimulator/Caches", label: "Simulator dyld caches",
        sublabel: "Regenerated on next boot", symbol: "memorychip", tint: "teal",
        tip: "Regenerated on next boot",
        tipCommand: "xcrun simctl shutdown all && rm -rf ~/Library/Developer/CoreSimulator/Caches/dyld",
        threshold: 3 * gigabyte, gate: .simulatorsBooted),
    Candidate(
        path: "\(home)/Library/Developer/Xcode/iOS DeviceSupport", label: "iOS DeviceSupport",
        sublabel: "Per-iOS debug symbols", symbol: "cable.connector", tint: "indigo",
        tip: "Keep only your current device's iOS version",
        tipCommand: "ls ~/Library/Developer/Xcode/iOS\\ DeviceSupport",
        threshold: 3 * gigabyte, gate: nil),
    Candidate(
        path: "\(home)/Library/Developer/Xcode/Archives", label: "Xcode archives",
        sublabel: "Release archives", symbol: "archivebox", tint: "brown",
        tip: "Old .xcarchives pile up per release",
        tipCommand: "open ~/Library/Developer/Xcode/Archives",
        threshold: 2 * gigabyte, gate: nil),
    Candidate(
        path: "\(home)/.android/avd", label: "Android AVDs",
        sublabel: "Snapshots take the space", symbol: "candybarphone", tint: "green",
        tip: "Wipe snapshots, keep the AVDs",
        tipCommand: "rm -rf ~/.android/avd/*.avd/snapshots",
        threshold: 10 * gigabyte, gate: .androidEmulatorRunning),
    Candidate(
        path: "\(home)/Library/Android", label: "Android SDK",
        sublabel: "System images and platforms", symbol: "wrench.and.screwdriver", tint: "green",
        tip: "Drop unused system images",
        tipCommand: "sdkmanager --list_installed",
        threshold: 12 * gigabyte, gate: .androidEmulatorRunning),
    Candidate(
        path: "\(home)/.gradle", label: "Gradle caches",
        sublabel: "Build cache", symbol: "cube", tint: "cyan",
        tip: "Safe to wipe, Gradle re-downloads",
        tipCommand: "rm -rf ~/.gradle/caches",
        threshold: 4 * gigabyte, gate: nil),
    Candidate(
        path: "\(home)/Library/Caches", label: "User caches",
        sublabel: "App caches", symbol: "folder", tint: "gray",
        tip: nil, tipCommand: nil,
        threshold: 4 * gigabyte, gate: nil),
    Candidate(
        path: "/opt/homebrew", label: "Homebrew",
        sublabel: "Bottles and caches", symbol: "mug", tint: "yellow",
        tip: "Purge old bottles and caches",
        tipCommand: "brew cleanup --prune=all",
        threshold: 8 * gigabyte, gate: nil),
]

struct Measurement {
    let candidate: Candidate
    let size: Int64
}

func tipMeasurements(from results: [Measurement]) -> [Measurement] {
    results.filter { $0.size >= $0.candidate.threshold && $0.candidate.tipCommand != nil }
}

// Rough upper bound of what the tips could free, split by whether a running
// simulator/emulator/Xcode currently makes the cleanup unsafe. Directory
// sizes, not exact savings — hence the "~" everywhere it is shown.
struct Reclaimable {
    var safeNow: Int64 = 0
    var gated: Int64 = 0
}

func reclaimable(from results: [Measurement], status: RuntimeStatus) -> Reclaimable {
    var totals = Reclaimable()
    for measurement in tipMeasurements(from: results) {
        if status.blocks(measurement.candidate.gate) {
            totals.gated += measurement.size
        } else {
            totals.safeNow += measurement.size
        }
    }
    return totals
}
