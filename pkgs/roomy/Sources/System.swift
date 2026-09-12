import Foundation

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

// MARK: - Drive discovery

func mountDevice(ofPath path: String) -> String? {
    var buffer = statfs()
    guard statfs(path, &buffer) == 0 else { return nil }
    return withUnsafePointer(to: &buffer.f_mntfromname) {
        $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { String(cString: $0) }
    }
}

// Stable across mount points: what `du` walked and what the drive card shows
// have to agree even when the path sits on a sibling volume of the same
// container, as everything under /nix does.
func volumeIdentifier(ofPath path: String) -> String {
    guard let device = mountDevice(ofPath: path) else { return path }
    return containerIdentifier(ofMountDevice: device) ?? device
}

// Only the volumes Finder itself would show: skipHiddenVolumes drops the
// nobrowse ones — /nix, the Preboot and VM volumes, mounted simulator runtime
// images — leaving the drives a person actually thinks of as drives.
func discoverVolumes() -> [Volume] {
    let keys: Set<URLResourceKey> = [
        .volumeLocalizedNameKey,
        .volumeIsInternalKey,
        .volumeIsBrowsableKey,
        .volumeIsLocalKey,
    ]
    let urls = FileManager.default.mountedVolumeURLs(
        includingResourceValuesForKeys: Array(keys), options: [.skipHiddenVolumes]) ?? []

    let volumes = urls.compactMap { url -> Volume? in
        let values = try? url.resourceValues(forKeys: keys)
        guard values?.volumeIsBrowsable ?? true, values?.volumeIsLocal ?? true else { return nil }
        return Volume(
            identifier: volumeIdentifier(ofPath: url.path),
            mountPoint: url.path,
            name: values?.volumeLocalizedName ?? url.lastPathComponent,
            isInternal: values?.volumeIsInternal ?? true)
    }

    // Internal first, and one entry per container: the boot drive leads because
    // it is the one that stops working when it fills up.
    var seen = Set<String>()
    return volumes
        .sorted { ($0.isInternal ? 0 : 1, $0.mountPoint) < ($1.isInternal ? 0 : 1, $1.mountPoint) }
        .filter { seen.insert($0.identifier).inserted }
}

extension DiskUsage {
    static func current(mountPoint: String) -> DiskUsage? {
        let url = URL(fileURLWithPath: mountPoint)
        guard
            let values = try? url.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeAvailableCapacityKey,
                .volumeTotalCapacityKey,
            ]),
            let important = values.volumeAvailableCapacityForImportantUsage,
            let strict = values.volumeAvailableCapacity,
            let total = values.volumeTotalCapacity,
            total > 0
        else { return nil }
        return DiskUsage(
            free: important,
            total: Int64(total),
            purgeable: max(0, important - Int64(strict))
        )
    }
}

// Xcode relocates DerivedData through this preference, which is exactly what
// the ext module sets to move it off the boot drive.
func xcodeDerivedDataLocation() -> String? {
    guard
        let raw = shell(
            "/usr/bin/defaults",
            ["read", "com.apple.dt.Xcode", "IDECustomDerivedDataLocation"])
    else { return nil }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

let candidates = makeCandidates(
    home: NSHomeDirectory(),
    environment: ProcessInfo.processInfo.environment,
    derivedData: xcodeDerivedDataLocation())
