import Foundation

var failures = 0

func expect(_ condition: Bool, _ label: String) {
    if !condition {
        print("FAIL: \(label)")
        failures += 1
    }
}

// compact
expect(compact(13_800_000_000) == "14G", "compact rounds >=10G to integer")
expect(compact(9_400_000_000) == "9.4G", "compact keeps one decimal <10G")
expect(compact(120 * gigabyte) == "120G", "compact three digits")
expect(compact(1_200 * gigabyte) == "1.2T", "compact switches to terabytes")

// parseDuOutput
expect(parseDuOutput("123456\t/nix/store\n") == 123_456 * 1024, "parseDuOutput kilobytes to bytes")
expect(parseDuOutput("garbage") == nil, "parseDuOutput rejects garbage")
expect(parseDuOutput("") == nil, "parseDuOutput rejects empty")

// freeSpaceLevel
expect(freeSpaceLevel(free: 5 * gigabyte, total: 228 * gigabyte) == .critical, "under 8G is critical")
expect(freeSpaceLevel(free: 12 * gigabyte, total: 228 * gigabyte) == .low, "under 15G floor is low")
expect(freeSpaceLevel(free: 40 * gigabyte, total: 228 * gigabyte) == .normal, "40G of 228G is normal")
expect(freeSpaceLevel(free: 30 * gigabyte, total: 400 * gigabyte) == .low, "under 10% of total is low")

// containerIdentifier
expect(
    containerIdentifier(ofMountDevice: "/dev/disk3s1s1") == "disk3",
    "the sealed boot snapshot belongs to its container")
expect(
    containerIdentifier(ofMountDevice: "/dev/disk3s7") == "disk3",
    "the nix volume shares the boot container")
expect(
    containerIdentifier(ofMountDevice: "/dev/disk5s1") == "disk5",
    "a second drive is its own container")
expect(containerIdentifier(ofMountDevice: "map auto_home") == nil, "non-disk devices have none")
expect(containerIdentifier(ofMountDevice: "/dev/diskX") == nil, "an unnumbered device has none")

// candidate locations
let env = [
    "GRADLE_USER_HOME": "/ext/cache/gradle",
    "ANDROID_AVD_HOME": "/ext/cache/android/avd",
    "ANDROID_SDK_ROOT": "/ext/cache/android/sdk",
    "CARGO_HOME": "",
]
let located = makeCandidates(home: "/Users/test", environment: env, derivedData: "/ext/cache/xcode/dd")
func path(of label: String, in list: [Candidate]) -> String? {
    list.first { $0.label == label }?.path
}
expect(path(of: "Gradle caches", in: located) == "/ext/cache/gradle", "the variable wins over ~")
expect(path(of: "Android AVDs", in: located) == "/ext/cache/android/avd", "AVDs follow their variable")
expect(path(of: "Android SDK", in: located) == "/ext/cache/android/sdk", "the SDK follows its variable")
expect(path(of: "Xcode DerivedData", in: located) == "/ext/cache/xcode/dd", "Xcode's preference wins")
expect(path(of: "Cargo home", in: located) == "/Users/test/.cargo", "an empty variable falls back")
expect(path(of: "npm cache", in: located) == "/Users/test/.npm", "an unset variable falls back")
expect(path(of: "Nix store", in: located) == "/nix/store", "the store is not relocatable")
expect(
    makeCandidates(home: "/Users/test", environment: [:], derivedData: nil)
        .first { $0.label == "Gradle caches" }?.path == "/Users/test/.gradle",
    "no variables at all keeps every path under home")

// cleanup commands follow the relocated paths
expect(
    located.first { $0.label == "Gradle caches" }?.tipCommand == "rm -rf /ext/cache/gradle/caches",
    "the gradle tip points at the volume the cache moved to")

// gating
expect(RuntimeStatus().blocks(nil) == false, "no gate never blocks")
expect(
    RuntimeStatus(simulatorsBooted: true).blocks(.simulatorsBooted),
    "booted simulator blocks simulator gate")
expect(
    !RuntimeStatus(simulatorsBooted: true).blocks(.androidEmulatorRunning),
    "booted simulator does not block emulator gate")
expect(
    RuntimeStatus(androidEmulatorRunning: true).blocks(.androidEmulatorRunning),
    "running emulator blocks emulator gate")
expect(
    RuntimeStatus(xcodeRunning: true).blocks(.xcodeRunning),
    "open Xcode blocks Xcode gate")

// tip selection
let candidates = makeCandidates(home: "/Users/test", environment: [:], derivedData: nil)
func measure(_ candidate: Candidate, _ size: Int64, volume: String = "disk3") -> Measurement {
    Measurement(candidate: candidate, size: size, volume: volume)
}
let big = measure(candidates[0], candidates[0].threshold + gigabyte)
let small = measure(candidates[1], 1)
let noCommand = measure(candidates.first { $0.tipCommand == nil }!, 100 * gigabyte)
let tips = tipMeasurements(from: [big, small, noCommand])
expect(tips.count == 1, "only above-threshold candidates with a command become tips")
expect(tips.first?.candidate.path == candidates[0].path, "the big candidate is the tip")

// reclaimable
let gatedCandidate = candidates.first { $0.gate == .androidEmulatorRunning }!
let openMeasurement = measure(candidates[0], candidates[0].threshold + gigabyte)
let gatedMeasurement = measure(gatedCandidate, gatedCandidate.threshold + gigabyte)
let idle = reclaimable(from: [openMeasurement, gatedMeasurement], status: RuntimeStatus())
expect(
    idle.safeNow == openMeasurement.size + gatedMeasurement.size,
    "everything counts as safe when nothing runs")
expect(idle.gated == 0, "nothing gated when nothing runs")
let busy = reclaimable(
    from: [openMeasurement, gatedMeasurement],
    status: RuntimeStatus(androidEmulatorRunning: true))
expect(busy.safeNow == openMeasurement.size, "running emulator moves its candidate out of safe")
expect(busy.gated == gatedMeasurement.size, "running emulator gates its candidate's size")
let tiny = reclaimable(from: [measure(candidates[0], 1)], status: RuntimeStatus())
expect(tiny.safeNow == 0 && tiny.gated == 0, "below-threshold sizes are not reclaimable")

// per-drive reports
let boot = Volume(identifier: "disk3", mountPoint: "/", name: "Macintosh HD", isInternal: true)
let external = Volume(identifier: "disk5", mountPoint: "/ext", name: "ext", isInternal: false)
let usage = [
    "disk3": DiskUsage(free: 40 * gigabyte, total: 245 * gigabyte, purgeable: 0),
    "disk5": DiskUsage(free: 222 * gigabyte, total: 256 * gigabyte, purgeable: 0),
]
let onExternal = measure(gatedCandidate, gatedCandidate.threshold + gigabyte, volume: "disk5")
let reports = buildReports(
    volumes: [boot, external],
    usage: { usage[$0.identifier] },
    measurements: [openMeasurement, onExternal],
    status: RuntimeStatus())
expect(reports.count == 2, "both drives are reported")
expect(reports[0].measurements.map(\.volume) == ["disk3"], "boot keeps only its own consumers")
expect(reports[1].measurements.map(\.volume) == ["disk5"], "the external drive keeps its own")
expect(reports[0].reclaimable.safeNow == openMeasurement.size, "reclaimable is counted per drive")
expect(reports[1].reclaimable.safeNow == onExternal.size, "the external total is its own")
expect(reports[0].usage.freePercent == 16, "free percentage comes from that drive's numbers")
expect(reports[1].usage.level == .normal, "a roomy external drive reads as normal")
expect(
    buildReports(
        volumes: [boot, external], usage: { usage[$0.identifier] },
        measurements: [], status: RuntimeStatus()
    ).allSatisfy { $0.measurements.isEmpty },
    "a drive with nothing measured still reports")
expect(
    buildReports(
        volumes: [boot, external], usage: { $0.identifier == "disk3" ? usage["disk3"] : nil },
        measurements: [], status: RuntimeStatus()
    ).map(\.volume) == [boot],
    "a drive whose capacity cannot be read is dropped")

// Volume presentation
expect(boot.symbol != external.symbol, "the two drives never share a glyph")
expect(boot.symbol == "internaldrive.fill", "the boot drive is the filled slab")
expect(boot.kind == "Internal" && external.kind == "External", "drives are labelled by bus")

if failures > 0 {
    print("\(failures) test(s) failed")
    exit(1)
}
print("all tests passed")
