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

// parseDuOutput
expect(parseDuOutput("123456\t/nix/store\n") == 123_456 * 1024, "parseDuOutput kilobytes to bytes")
expect(parseDuOutput("garbage") == nil, "parseDuOutput rejects garbage")
expect(parseDuOutput("") == nil, "parseDuOutput rejects empty")

// freeSpaceLevel
expect(freeSpaceLevel(free: 5 * gigabyte, total: 228 * gigabyte) == .critical, "under 8G is critical")
expect(freeSpaceLevel(free: 12 * gigabyte, total: 228 * gigabyte) == .low, "under 15G floor is low")
expect(freeSpaceLevel(free: 40 * gigabyte, total: 228 * gigabyte) == .normal, "40G of 228G is normal")
expect(freeSpaceLevel(free: 30 * gigabyte, total: 400 * gigabyte) == .low, "under 10% of total is low")

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
let big = Measurement(candidate: candidates[0], size: candidates[0].threshold + gigabyte)
let small = Measurement(candidate: candidates[1], size: 1)
let noCommand = Measurement(
    candidate: candidates.first { $0.tipCommand == nil }!,
    size: 100 * gigabyte)
let tips = tipMeasurements(from: [big, small, noCommand])
expect(tips.count == 1, "only above-threshold candidates with a command become tips")
expect(tips.first?.candidate.path == candidates[0].path, "the big candidate is the tip")

// reclaimable
let gatedCandidate = candidates.first { $0.gate == .androidEmulatorRunning }!
let openMeasurement = Measurement(candidate: candidates[0], size: candidates[0].threshold + gigabyte)
let gatedMeasurement = Measurement(
    candidate: gatedCandidate, size: gatedCandidate.threshold + gigabyte)
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
let tiny = reclaimable(
    from: [Measurement(candidate: candidates[0], size: 1)], status: RuntimeStatus())
expect(tiny.safeNow == 0 && tiny.gated == 0, "below-threshold sizes are not reclaimable")

if failures > 0 {
    print("\(failures) test(s) failed")
    exit(1)
}
print("all tests passed")
