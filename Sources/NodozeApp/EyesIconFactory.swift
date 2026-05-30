import AppKit

enum MenuBarIconStyle: String {
    case fullColor
    case monochrome
}

enum EyesIconFactory {
    private static let imageSize = NSSize(width: 56, height: 28)
    private static let leftEye = NSRect(x: 8.0, y: 2.6, width: 19.0, height: 22.0)
    private static let rightEye = NSRect(x: 27.0, y: 2.6, width: 19.0, height: 22.0)

    static func make(
        enabled: Bool,
        busy: Bool,
        style: MenuBarIconStyle = .fullColor,
        leftPupilOffset: CGPoint = .zero,
        rightPupilOffset: CGPoint = .zero,
        blinking: Bool = false,
        sleepingPhase: Int = 0
    ) -> NSImage {
        let image = NSImage(size: imageSize)

        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high

        if style == .monochrome {
            drawMonochromeIcon(
                enabled: enabled,
                busy: busy,
                leftPupilOffset: leftPupilOffset,
                rightPupilOffset: rightPupilOffset,
                blinking: blinking,
                sleepingPhase: sleepingPhase
            )
        } else if busy {
            drawOpenEyes(leftPupilOffset: leftPupilOffset, rightPupilOffset: rightPupilOffset)
            drawBusyUnderline()
        } else if enabled && blinking {
            drawBlink()
        } else if enabled {
            drawOpenEyes(leftPupilOffset: leftPupilOffset, rightPupilOffset: rightPupilOffset)
        } else {
            drawDroopyEyes(sleepingPhase: sleepingPhase)
        }

        image.unlockFocus()
        image.isTemplate = style == .monochrome
        return image
    }

    private static func drawMonochromeIcon(
        enabled: Bool,
        busy: Bool,
        leftPupilOffset: CGPoint,
        rightPupilOffset: CGPoint,
        blinking: Bool,
        sleepingPhase: Int
    ) {
        if enabled && blinking {
            drawMonochromeBlink()
        } else if enabled || busy {
            drawMonochromeOpenEyes(leftPupilOffset: leftPupilOffset, rightPupilOffset: rightPupilOffset)
        } else {
            drawMonochromeDroopyEyes(sleepingPhase: sleepingPhase)
        }

        if busy {
            drawMonochromeBusyUnderline()
        }
    }

    private static func drawMonochromeOpenEyes(leftPupilOffset: CGPoint, rightPupilOffset: CGPoint) {
        drawMonochromeEyeOutlines()
        drawMonochromeBrows(enabled: true)
        drawMonochromePupils(leftOffset: leftPupilOffset, rightOffset: rightPupilOffset, lowered: false)
    }

    private static func drawMonochromeDroopyEyes(sleepingPhase: Int) {
        drawMonochromeTiredEyeShapes()
        drawMonochromeTiredBrows()
        drawMonochromeTiredPupils()
        drawMonochromeTiredLids()
        drawMonochromeSleepingZs(phase: sleepingPhase)
    }

    private static func drawMonochromeBlink() {
        for eye in [leftEye, rightEye] {
            drawMonochromeUpperLid(for: eye, openness: 0.02)
        }
        drawMonochromeBrows(enabled: true)
    }

    private static func drawMonochromeEyeOutlines() {
        templateColor(alpha: 0.95).setStroke()

        for eye in [leftEye, rightEye] {
            let path = NSBezierPath(ovalIn: eye)
            path.lineWidth = 1.55
            path.stroke()
        }
    }

    private static func drawMonochromePupils(leftOffset: CGPoint, rightOffset: CGPoint, lowered: Bool) {
        let leftCenter = CGPoint(x: leftEye.midX + leftOffset.x, y: leftEye.midY + leftOffset.y)
        let rightCenter = CGPoint(x: rightEye.midX + rightOffset.x, y: rightEye.midY + rightOffset.y)
        let radius: CGFloat = lowered ? 2.7 : 3.35

        templateColor(alpha: 1.0).setFill()
        NSBezierPath(ovalIn: NSRect(x: leftCenter.x - radius, y: leftCenter.y - radius, width: radius * 2, height: radius * 2)).fill()
        NSBezierPath(ovalIn: NSRect(x: rightCenter.x - radius, y: rightCenter.y - radius, width: radius * 2, height: radius * 2)).fill()
    }

    private static func drawMonochromeUpperLid(for eye: NSRect, openness: CGFloat) {
        templateColor(alpha: 1.0).setStroke()
        let path = upperLidEdgePath(for: eye, openness: openness)
        path.lineWidth = 2.0
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func drawMonochromeBrows(enabled: Bool) {
        templateColor(alpha: 1.0).setStroke()

        let left = NSBezierPath()
        let right = NSBezierPath()

        if enabled {
            left.move(to: NSPoint(x: leftEye.minX + 0.7, y: leftEye.maxY + 0.3))
            left.curve(
                to: NSPoint(x: leftEye.maxX - 2.0, y: leftEye.maxY - 0.3),
                controlPoint1: NSPoint(x: leftEye.minX + 4.2, y: leftEye.maxY + 3.6),
                controlPoint2: NSPoint(x: leftEye.midX + 0.8, y: leftEye.maxY + 3.5)
            )

            right.move(to: NSPoint(x: rightEye.minX + 2.0, y: rightEye.maxY - 0.3))
            right.curve(
                to: NSPoint(x: rightEye.maxX - 0.7, y: rightEye.maxY + 0.3),
                controlPoint1: NSPoint(x: rightEye.midX - 0.8, y: rightEye.maxY + 3.5),
                controlPoint2: NSPoint(x: rightEye.maxX - 4.2, y: rightEye.maxY + 3.6)
            )
        } else {
            left.move(to: NSPoint(x: leftEye.minX + 0.3, y: leftEye.maxY - 3.1))
            left.curve(
                to: NSPoint(x: leftEye.maxX - 1.5, y: leftEye.maxY - 0.8),
                controlPoint1: NSPoint(x: leftEye.minX + 4.2, y: leftEye.maxY - 1.7),
                controlPoint2: NSPoint(x: leftEye.midX + 1.0, y: leftEye.maxY + 0.1)
            )

            right.move(to: NSPoint(x: rightEye.minX + 1.5, y: rightEye.maxY - 0.8))
            right.curve(
                to: NSPoint(x: rightEye.maxX - 0.3, y: rightEye.maxY - 3.1),
                controlPoint1: NSPoint(x: rightEye.midX - 1.0, y: rightEye.maxY + 0.1),
                controlPoint2: NSPoint(x: rightEye.maxX - 4.2, y: rightEye.maxY - 1.7)
            )
        }

        for brow in [left, right] {
            brow.lineWidth = 1.7
            brow.lineCapStyle = .round
            brow.stroke()
        }
    }

    private static func drawMonochromeEyeBags() {
        templateColor(alpha: 0.55).setStroke()

        let paths: [NSBezierPath] = [leftEye, rightEye].map { eye in
            let path = NSBezierPath()
            path.move(to: NSPoint(x: eye.minX + 4.0, y: eye.minY + 1.7))
            path.curve(
                to: NSPoint(x: eye.maxX - 4.0, y: eye.minY + 1.8),
                controlPoint1: NSPoint(x: eye.midX - 3.8, y: eye.minY - 0.4),
                controlPoint2: NSPoint(x: eye.midX + 3.8, y: eye.minY - 0.4)
            )
            return path
        }

        for path in paths {
            path.lineWidth = 0.95
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    private static func drawMonochromeTiredEyeShapes() {
        templateColor(alpha: 0.95).setStroke()

        for (index, eye) in [leftEye, rightEye].enumerated() {
            let path = tiredEyePath(for: eye, index: index)
            path.lineWidth = 1.45
            path.stroke()
        }
    }

    private static func drawMonochromeTiredBrows() {
        templateColor(alpha: 1.0).setStroke()

        for path in tiredBrowPaths() {
            path.lineWidth = 2.2
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    private static func drawMonochromeTiredPupils() {
        templateColor(alpha: 1.0).setFill()

        let pupils = [
            NSRect(x: leftEye.midX + 2.2, y: leftEye.midY - 2.0, width: 2.0, height: 2.0),
            NSRect(x: rightEye.midX - 4.2, y: rightEye.midY - 2.0, width: 2.0, height: 2.0),
        ]

        for pupil in pupils {
            NSBezierPath(ovalIn: pupil).fill()
        }
    }

    private static func drawMonochromeTiredLids() {
        templateColor(alpha: 0.95).setStroke()

        for (index, eye) in [leftEye, rightEye].enumerated() {
            let path = tiredLidPath(for: eye, index: index)
            path.lineWidth = 1.75
            path.lineCapStyle = .round
            path.stroke()
        }

        templateColor(alpha: 0.3).setStroke()

        for (index, eye) in [leftEye, rightEye].enumerated() {
            let path = tiredBagPath(for: eye, index: index)
            path.lineWidth = 0.7
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    private static func drawMonochromeSleepingZs(phase: Int) {
        let strings = ["Z", "z"]
        let positions = [
            NSPoint(x: 42.0, y: 17.8),
            NSPoint(x: 46.0, y: 21.0),
        ]

        for index in strings.indices {
            let age = (index + phase) % strings.count
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: age == 0 ? 5.5 : 4.8),
                .foregroundColor: templateColor(alpha: age == 0 ? 0.9 : 0.62),
            ]
            strings[index].draw(at: positions[index], withAttributes: attributes)
        }
    }

    private static func drawMonochromeBusyUnderline() {
        templateColor(alpha: 0.85).setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: leftEye.minX + 2.0, y: 0.9))
        path.line(to: NSPoint(x: rightEye.maxX - 6.0, y: 0.9))
        path.lineWidth = 1.2
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func drawOpenEyes(
        leftPupilOffset: CGPoint = .zero,
        rightPupilOffset: CGPoint = .zero
    ) {
        drawEyeShells()
        drawBrows(enabled: true)
        drawPupils(leftOffset: leftPupilOffset, rightOffset: rightPupilOffset, lowered: false)
        drawOpenLidDetails()
    }

    private static func drawDroopyEyes(sleepingPhase: Int) {
        drawTiredEyeShells()
        drawTiredBrows()
        drawTiredPupils()
        drawTiredLidFills()
        drawTiredLidLines()
        drawSubtleTiredLines()
        drawSleepingZs(phase: sleepingPhase)
    }

    private static func drawBlink() {
        drawEyeShells()
        drawBrows(enabled: true)

        for eye in [leftEye, rightEye] {
            drawUpperLidFill(for: eye, openness: 0.02, color: lidColor())
            drawUpperLidEdge(for: eye, openness: 0.02, alpha: 0.9, width: 1.8)
        }
    }

    private static func drawEyeShells() {
        for eye in [leftEye, rightEye] {
            let path = NSBezierPath(ovalIn: eye)
            eyeColor().setFill()
            path.fill()
            strokeColor().setStroke()
            path.lineWidth = 1.25
            path.stroke()
        }
    }

    private static func drawPupils(leftOffset: CGPoint, rightOffset: CGPoint, lowered: Bool) {
        let leftCenter = CGPoint(x: leftEye.midX + leftOffset.x, y: leftEye.midY + leftOffset.y)
        let rightCenter = CGPoint(x: rightEye.midX + rightOffset.x, y: rightEye.midY + rightOffset.y)
        let radius: CGFloat = lowered ? 2.9 : 3.4

        strokeColor().setFill()
        NSBezierPath(ovalIn: NSRect(x: leftCenter.x - radius, y: leftCenter.y - radius, width: radius * 2, height: radius * 2)).fill()
        NSBezierPath(ovalIn: NSRect(x: rightCenter.x - radius, y: rightCenter.y - radius, width: radius * 2, height: radius * 2)).fill()

        NSColor.white.withAlphaComponent(0.92).setFill()
        NSBezierPath(ovalIn: NSRect(x: leftCenter.x - 1.4, y: leftCenter.y + 1.0, width: 1.3, height: 1.3)).fill()
        NSBezierPath(ovalIn: NSRect(x: rightCenter.x - 1.4, y: rightCenter.y + 1.0, width: 1.3, height: 1.3)).fill()
    }

    private static func drawOpenLidDetails() {
        for eye in [leftEye, rightEye] {
            drawUpperLidEdge(for: eye, openness: 0.98, alpha: 0.25, width: 1.0)
            drawLowerLidEdge(for: eye, alpha: 0.22)
        }
    }

    private static func drawDroopyLids() {
        for eye in [leftEye, rightEye] {
            drawUpperLidFill(for: eye, openness: 0.16, color: lidColor())
            drawUpperLidEdge(for: eye, openness: 0.16, alpha: 0.9, width: 1.75)
            drawLidCrease(for: eye, alpha: 0.52)
        }
    }

    private static func drawUpperLidFill(for eye: NSRect, openness: CGFloat, color: NSColor) {
        let path = upperLidPath(for: eye, openness: openness)

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(ovalIn: eye).addClip()
        color.setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawUpperLidEdge(for eye: NSRect, openness: CGFloat, alpha: CGFloat, width: CGFloat) {
        strokeColor().withAlphaComponent(alpha).setStroke()
        let path = upperLidEdgePath(for: eye, openness: openness)
        path.lineWidth = width
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func drawLowerLidEdge(for eye: NSRect, alpha: CGFloat) {
        strokeColor().withAlphaComponent(alpha).setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: eye.minX + 3.2, y: eye.minY + 2.0))
        path.curve(
            to: NSPoint(x: eye.maxX - 3.2, y: eye.minY + 2.0),
            controlPoint1: NSPoint(x: eye.midX - 4.0, y: eye.minY - 0.8),
            controlPoint2: NSPoint(x: eye.midX + 4.0, y: eye.minY - 0.8)
        )
        path.lineWidth = 0.95
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func drawLidCrease(for eye: NSRect, alpha: CGFloat) {
        strokeColor().withAlphaComponent(alpha).setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: eye.minX + 2.7, y: eye.maxY - 6.8))
        path.curve(
            to: NSPoint(x: eye.maxX - 2.7, y: eye.maxY - 6.5),
            controlPoint1: NSPoint(x: eye.midX - 4.0, y: eye.maxY - 4.2),
            controlPoint2: NSPoint(x: eye.midX + 4.0, y: eye.maxY - 4.2)
        )
        path.lineWidth = 0.85
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func upperLidPath(for eye: NSRect, openness: CGFloat) -> NSBezierPath {
        let closedness = 1 - openness
        let sideY = eye.maxY - 4.0 - closedness * 6.5
        let centerY = eye.maxY - 1.6 - closedness * 17.0
        let path = NSBezierPath()
        path.move(to: NSPoint(x: eye.minX - 1.2, y: eye.maxY + 3.0))
        path.line(to: NSPoint(x: eye.maxX + 1.2, y: eye.maxY + 3.0))
        path.line(to: NSPoint(x: eye.maxX + 1.2, y: sideY))
        path.curve(
            to: NSPoint(x: eye.minX - 1.2, y: sideY),
            controlPoint1: NSPoint(x: eye.midX + 7.0, y: centerY),
            controlPoint2: NSPoint(x: eye.midX - 7.0, y: centerY)
        )
        path.close()
        return path
    }

    private static func upperLidEdgePath(for eye: NSRect, openness: CGFloat) -> NSBezierPath {
        let closedness = 1 - openness
        let sideY = eye.maxY - 4.0 - closedness * 6.5
        let centerY = eye.maxY - 1.6 - closedness * 17.0
        let path = NSBezierPath()
        path.move(to: NSPoint(x: eye.minX - 1.2, y: sideY))
        path.curve(
            to: NSPoint(x: eye.maxX + 1.2, y: sideY),
            controlPoint1: NSPoint(x: eye.midX - 7.0, y: centerY),
            controlPoint2: NSPoint(x: eye.midX + 7.0, y: centerY)
        )
        return path
    }

    private static func drawBrows(enabled: Bool) {
        strokeColor().setStroke()

        let left = NSBezierPath()
        let right = NSBezierPath()

        if enabled {
            left.move(to: NSPoint(x: leftEye.minX + 0.2, y: leftEye.maxY + 0.2))
            left.curve(
                to: NSPoint(x: leftEye.maxX - 1.6, y: leftEye.maxY - 0.2),
                controlPoint1: NSPoint(x: leftEye.minX + 4.0, y: leftEye.maxY + 4.2),
                controlPoint2: NSPoint(x: leftEye.midX + 1.0, y: leftEye.maxY + 4.0)
            )

            right.move(to: NSPoint(x: rightEye.minX + 1.6, y: rightEye.maxY - 0.2))
            right.curve(
                to: NSPoint(x: rightEye.maxX - 0.2, y: rightEye.maxY + 0.2),
                controlPoint1: NSPoint(x: rightEye.midX - 1.0, y: rightEye.maxY + 4.0),
                controlPoint2: NSPoint(x: rightEye.maxX - 4.0, y: rightEye.maxY + 4.2)
            )
        } else {
            left.move(to: NSPoint(x: leftEye.minX + 0.3, y: leftEye.maxY - 3.1))
            left.curve(
                to: NSPoint(x: leftEye.maxX - 1.5, y: leftEye.maxY - 0.8),
                controlPoint1: NSPoint(x: leftEye.minX + 4.2, y: leftEye.maxY - 1.7),
                controlPoint2: NSPoint(x: leftEye.midX + 1.0, y: leftEye.maxY + 0.1)
            )

            right.move(to: NSPoint(x: rightEye.minX + 1.5, y: rightEye.maxY - 0.8))
            right.curve(
                to: NSPoint(x: rightEye.maxX - 0.3, y: rightEye.maxY - 3.1),
                controlPoint1: NSPoint(x: rightEye.midX - 1.0, y: rightEye.maxY + 0.1),
                controlPoint2: NSPoint(x: rightEye.maxX - 4.2, y: rightEye.maxY - 1.7)
            )
        }

        for brow in [left, right] {
            brow.lineWidth = 1.85
            brow.lineCapStyle = .round
            brow.stroke()
        }
    }

    private static func drawSubtleTiredLines() {
        strokeColor().withAlphaComponent(0.24).setStroke()

        for (index, eye) in [leftEye, rightEye].enumerated() {
            let path = tiredBagPath(for: eye, index: index)
            path.lineWidth = 0.7
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    private static func drawTiredEyeShells() {
        for (index, eye) in [leftEye, rightEye].enumerated() {
            let path = tiredEyePath(for: eye, index: index)
            eyeColor().setFill()
            path.fill()
            strokeColor().setStroke()
            path.lineWidth = 1.25
            path.stroke()
        }
    }

    private static func drawTiredBrows() {
        strokeColor().setStroke()

        for path in tiredBrowPaths() {
            path.lineWidth = 2.25
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    private static func drawTiredPupils() {
        strokeColor().setFill()

        let pupils = [
            NSRect(x: leftEye.midX + 2.0, y: leftEye.midY - 2.2, width: 2.2, height: 2.2),
            NSRect(x: rightEye.midX - 4.2, y: rightEye.midY - 2.2, width: 2.2, height: 2.2),
        ]

        for pupil in pupils {
            NSBezierPath(ovalIn: pupil).fill()
        }
    }

    private static func drawTiredLidLines() {
        strokeColor().withAlphaComponent(0.92).setStroke()

        for (index, eye) in [leftEye, rightEye].enumerated() {
            let path = tiredLidPath(for: eye, index: index)
            path.lineWidth = 1.65
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    private static func drawTiredLidFills() {
        lidColor().setFill()

        for (index, eye) in [leftEye, rightEye].enumerated() {
            NSGraphicsContext.saveGraphicsState()
            tiredEyePath(for: eye, index: index).addClip()
            tiredLidFillPath(for: eye, index: index).fill()
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    private static func tiredEyePath(for eye: NSRect, index: Int) -> NSBezierPath {
        let path = NSBezierPath()

        if index == 0 {
            path.move(to: NSPoint(x: eye.minX - 1.4, y: eye.midY - 1.0))
            path.curve(
                to: NSPoint(x: eye.maxX + 1.3, y: eye.midY + 1.0),
                controlPoint1: NSPoint(x: eye.minX + 1.8, y: eye.maxY + 1.6),
                controlPoint2: NSPoint(x: eye.midX + 7.0, y: eye.maxY + 1.2)
            )
            path.curve(
                to: NSPoint(x: eye.minX - 1.4, y: eye.midY - 1.0),
                controlPoint1: NSPoint(x: eye.maxX - 2.3, y: eye.minY - 0.7),
                controlPoint2: NSPoint(x: eye.minX + 3.0, y: eye.minY - 0.2)
            )
        } else {
            path.move(to: NSPoint(x: eye.minX - 1.3, y: eye.midY + 1.0))
            path.curve(
                to: NSPoint(x: eye.maxX + 1.4, y: eye.midY - 1.0),
                controlPoint1: NSPoint(x: eye.midX - 7.0, y: eye.maxY + 1.2),
                controlPoint2: NSPoint(x: eye.maxX - 1.8, y: eye.maxY + 1.6)
            )
            path.curve(
                to: NSPoint(x: eye.minX - 1.3, y: eye.midY + 1.0),
                controlPoint1: NSPoint(x: eye.maxX - 3.0, y: eye.minY - 0.2),
                controlPoint2: NSPoint(x: eye.minX + 2.3, y: eye.minY - 0.7)
            )
        }

        path.close()
        return path
    }

    private static func tiredLidPath(for eye: NSRect, index: Int) -> NSBezierPath {
        let path = NSBezierPath()

        if index == 0 {
            path.move(to: NSPoint(x: eye.minX - 1.7, y: eye.midY - 1.0))
            path.curve(
                to: NSPoint(x: eye.maxX + 1.5, y: eye.midY + 1.6),
                controlPoint1: NSPoint(x: eye.minX + 5.5, y: eye.midY + 0.8),
                controlPoint2: NSPoint(x: eye.midX + 5.6, y: eye.midY + 1.7)
            )
        } else {
            path.move(to: NSPoint(x: eye.minX - 1.5, y: eye.midY + 1.6))
            path.curve(
                to: NSPoint(x: eye.maxX + 1.7, y: eye.midY - 1.0),
                controlPoint1: NSPoint(x: eye.midX - 5.6, y: eye.midY + 1.7),
                controlPoint2: NSPoint(x: eye.maxX - 5.5, y: eye.midY + 0.8)
            )
        }

        return path
    }

    private static func tiredLidFillPath(for eye: NSRect, index: Int) -> NSBezierPath {
        let path = tiredLidPath(for: eye, index: index)
        path.line(to: NSPoint(x: eye.maxX + 2.0, y: eye.maxY + 4.0))
        path.line(to: NSPoint(x: eye.minX - 2.0, y: eye.maxY + 4.0))
        path.close()
        return path
    }

    private static func tiredBagPath(for eye: NSRect, index: Int) -> NSBezierPath {
        let path = NSBezierPath()

        if index == 0 {
            path.move(to: NSPoint(x: eye.minX + 2.8, y: eye.minY + 2.1))
            path.curve(
                to: NSPoint(x: eye.maxX - 1.4, y: eye.minY + 3.2),
                controlPoint1: NSPoint(x: eye.midX - 2.8, y: eye.minY - 0.1),
                controlPoint2: NSPoint(x: eye.midX + 4.0, y: eye.minY + 0.2)
            )
        } else {
            path.move(to: NSPoint(x: eye.minX + 1.4, y: eye.minY + 3.2))
            path.curve(
                to: NSPoint(x: eye.maxX - 2.8, y: eye.minY + 2.1),
                controlPoint1: NSPoint(x: eye.midX - 4.0, y: eye.minY + 0.2),
                controlPoint2: NSPoint(x: eye.midX + 2.8, y: eye.minY - 0.1)
            )
        }

        return path
    }

    private static func tiredBrowPaths() -> [NSBezierPath] {
        let left = NSBezierPath()
        left.move(to: NSPoint(x: leftEye.minX - 0.5, y: leftEye.maxY - 1.0))
        left.curve(
            to: NSPoint(x: leftEye.maxX + 0.7, y: leftEye.maxY - 5.7),
            controlPoint1: NSPoint(x: leftEye.minX + 5.5, y: leftEye.maxY + 5.0),
            controlPoint2: NSPoint(x: leftEye.midX + 6.2, y: leftEye.maxY + 3.0)
        )

        let right = NSBezierPath()
        right.move(to: NSPoint(x: rightEye.minX - 0.7, y: rightEye.maxY - 5.7))
        right.curve(
            to: NSPoint(x: rightEye.maxX + 0.5, y: rightEye.maxY - 1.0),
            controlPoint1: NSPoint(x: rightEye.midX - 6.2, y: rightEye.maxY + 3.0),
            controlPoint2: NSPoint(x: rightEye.maxX - 5.5, y: rightEye.maxY + 5.0)
        )

        return [left, right]
    }

    private static func drawSleepingZs(phase: Int) {
        let strings = ["Z", "z", "z"]
        let positions = [
            NSPoint(x: 40.0, y: 17.1),
            NSPoint(x: 44.0, y: 20.2),
            NSPoint(x: 47.0, y: 22.1),
        ]

        for index in strings.indices {
            let age = (index + phase) % strings.count
            let alpha = [0.48, 0.72, 0.95][age]
            let size: CGFloat = [4.8, 5.5, 6.2][age]
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: size),
                .foregroundColor: sleepTextColor().withAlphaComponent(alpha),
            ]
            strings[index].draw(at: positions[index], withAttributes: attributes)
        }
    }

    private static func drawBusyUnderline() {
        NSColor.systemGreen.withAlphaComponent(0.9).setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: leftEye.minX + 1.2, y: 0.8))
        path.curve(
            to: NSPoint(x: rightEye.maxX - 5.0, y: 0.8),
            controlPoint1: NSPoint(x: leftEye.midX, y: -0.8),
            controlPoint2: NSPoint(x: rightEye.midX, y: -0.8)
        )
        path.lineWidth = 1.1
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func strokeColor() -> NSColor {
        NSColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)
    }

    private static func eyeColor() -> NSColor {
        NSColor(red: 1.0, green: 0.99, blue: 0.97, alpha: 1)
    }

    private static func lidColor() -> NSColor {
        NSColor(red: 0.87, green: 0.84, blue: 0.78, alpha: 1)
    }

    private static func sleepTextColor() -> NSColor {
        NSColor(red: 0.62, green: 0.62, blue: 0.64, alpha: 1)
    }

    private static func templateColor(alpha: CGFloat) -> NSColor {
        NSColor.black.withAlphaComponent(alpha)
    }
}
