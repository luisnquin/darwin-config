import AppKit
import ApplicationServices

func idleSeconds() -> TimeInterval {
    CGEventSource.secondsSinceLastEventType(
        .combinedSessionState, eventType: CGEventType(rawValue: UInt32.max)!
    )
}

func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
        return nil
    }
    return value
}

func sponsorBarFrame() -> CGRect? {
    guard let application = NSRunningApplication.runningApplications(withBundleIdentifier: "com.kickbot.sponsorbar").first,
          let windows = attribute(AXUIElementCreateApplication(application.processIdentifier), kAXWindowsAttribute) as? [AXUIElement] else {
        return nil
    }

    for window in windows {
        guard let positionRaw = attribute(window, kAXPositionAttribute),
              let sizeRaw = attribute(window, kAXSizeAttribute),
              CFGetTypeID(positionRaw) == AXValueGetTypeID(),
              CFGetTypeID(sizeRaw) == AXValueGetTypeID() else {
            continue
        }
        let positionValue = positionRaw as! AXValue
        let sizeValue = sizeRaw as! AXValue
        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue, .cgPoint, &position),
              AXValueGetValue(sizeValue, .cgSize, &size) else {
            continue
        }
        let frame = CGRect(origin: position, size: size)
        if frame.minY >= 0, frame.minY < 40, frame.width >= 100, frame.width < 400,
           frame.height >= 15, frame.height < 60 {
            return frame
        }
    }
    return nil
}

func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
    hypot(first.x - second.x, first.y - second.y)
}

func move(_ start: CGPoint, to end: CGPoint, duration: Double) {
    let steps = max(12, Int(duration / 0.016))
    let bend = CGFloat.random(in: -5...5)
    for step in 1...steps {
        let progress = Double(step) / Double(steps)
        let eased = progress * progress * (3 - 2 * progress)
        let point = CGPoint(
            x: start.x + (end.x - start.x) * eased + bend * sin(.pi * progress),
            y: start.y + (end.y - start.y) * eased
        )
        CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point,
                mouseButton: .left)?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: duration / Double(steps))
    }
}

guard idleSeconds() >= 300 else { exit(0) }
Thread.sleep(forTimeInterval: Double.random(in: 0...90))
guard idleSeconds() >= 300,
      AXIsProcessTrusted(),
      let frame = sponsorBarFrame(),
      let original = CGEvent(source: nil)?.location else {
    exit(0)
}

let target = CGPoint(x: frame.midX + CGFloat.random(in: -8...8), y: frame.midY)
let bounds = CGDisplayBounds(CGMainDisplayID())
guard bounds.contains(target) else { exit(0) }

let lower = CGPoint(x: original.x, y: max(original.y, 85))
let approach = CGPoint(x: target.x + CGFloat.random(in: -35...35), y: 85)
move(original, to: lower, duration: 0.2)
move(lower, to: approach, duration: Double.random(in: 0.3...0.7))
move(approach, to: target, duration: 0.25)
Thread.sleep(forTimeInterval: Double.random(in: 0.8...1.5))

if let current = CGEvent(source: nil)?.location, distance(current, target) < 15 {
    move(target, to: approach, duration: 0.2)
    move(approach, to: lower, duration: Double.random(in: 0.3...0.7))
    move(lower, to: original, duration: 0.2)
}
