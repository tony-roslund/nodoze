import AppKit

enum EyesIconFactory {
    static func make(
        enabled: Bool,
        busy: Bool,
        leftPupilOffset: CGPoint = .zero,
        rightPupilOffset: CGPoint = .zero,
        blinking: Bool = false,
        sleepingPhase: Int = 0
    ) -> NSImage {
        let size = NSSize(width: 38, height: 22)
        let image = NSImage(size: size)

        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high

        if busy {
            drawBusy(in: NSRect(origin: .zero, size: size))
        } else if enabled && blinking {
            drawBlink(in: NSRect(origin: .zero, size: size))
        } else if enabled {
            drawOpenEyes(
                in: NSRect(origin: .zero, size: size),
                leftPupilOffset: leftPupilOffset,
                rightPupilOffset: rightPupilOffset
            )
        } else {
            drawDroopyEyes(in: NSRect(origin: .zero, size: size), sleepingPhase: sleepingPhase)
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func drawOpenEyes(
        in rect: NSRect,
        leftPupilOffset: CGPoint = .zero,
        rightPupilOffset: CGPoint = .zero
    ) {
        let stroke = NSColor.labelColor
        let fill = NSColor.controlBackgroundColor
        let pupil = NSColor.labelColor
        let left = NSRect(x: 4.5, y: 2.4, width: 14.5, height: 17)
        let right = NSRect(x: 19, y: 2.4, width: 14.5, height: 17)

        for eye in [left, right] {
            let path = NSBezierPath(ovalIn: eye)
            fill.setFill()
            path.fill()
            stroke.setStroke()
            path.lineWidth = 1.45
            path.stroke()
        }

        drawBrows(enabled: true)

        pupil.setFill()
        NSBezierPath(ovalIn: NSRect(
            x: 11.8 + leftPupilOffset.x,
            y: 8.2 + leftPupilOffset.y,
            width: 5.2,
            height: 5.2
        )).fill()
        NSBezierPath(ovalIn: NSRect(
            x: 21.5 + rightPupilOffset.x,
            y: 8.2 + rightPupilOffset.y,
            width: 5.2,
            height: 5.2
        )).fill()

        let highlight = NSColor.controlBackgroundColor.withAlphaComponent(0.9)
        highlight.setFill()
        NSBezierPath(ovalIn: NSRect(x: 13.2 + leftPupilOffset.x, y: 11.8 + leftPupilOffset.y, width: 1.2, height: 1.2)).fill()
        NSBezierPath(ovalIn: NSRect(x: 22.9 + rightPupilOffset.x, y: 11.8 + rightPupilOffset.y, width: 1.2, height: 1.2)).fill()
    }

    private static func drawDroopyEyes(in rect: NSRect, sleepingPhase: Int = 0) {
        let stroke = NSColor.labelColor
        let fill = NSColor.controlBackgroundColor
        let left = NSRect(x: 4.5, y: 3.2, width: 14.5, height: 15)
        let right = NSRect(x: 19, y: 3.2, width: 14.5, height: 15)

        for eye in [left, right] {
            let path = NSBezierPath(ovalIn: eye)
            fill.setFill()
            path.fill()
            stroke.setStroke()
            path.lineWidth = 1.45
            path.stroke()
        }

        drawBrows(enabled: false)

        stroke.setFill()
        NSBezierPath(ovalIn: NSRect(x: 12, y: 5.6, width: 4.4, height: 4.4)).fill()
        NSBezierPath(ovalIn: NSRect(x: 21.7, y: 5.6, width: 4.4, height: 4.4)).fill()

        let eyelid = sleepLidColor()
        eyelid.setFill()
        for eye in [left, right] {
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(ovalIn: eye).addClip()
            NSRect(x: eye.minX - 1, y: 9.2, width: eye.width + 2, height: 10).fill()
            NSGraphicsContext.restoreGraphicsState()
        }

        stroke.setStroke()
        let leftLid = NSBezierPath()
        leftLid.move(to: NSPoint(x: 4.5, y: 9.5))
        leftLid.curve(
            to: NSPoint(x: 19, y: 9.1),
            controlPoint1: NSPoint(x: 8.4, y: 7.1),
            controlPoint2: NSPoint(x: 15.2, y: 7.4)
        )
        leftLid.lineWidth = 2.25
        leftLid.stroke()

        let rightLid = NSBezierPath()
        rightLid.move(to: NSPoint(x: 19, y: 9.1))
        rightLid.curve(
            to: NSPoint(x: 33.5, y: 9.5),
            controlPoint1: NSPoint(x: 23.0, y: 7.4),
            controlPoint2: NSPoint(x: 29.6, y: 7.1)
        )
        rightLid.lineWidth = 2.25
        rightLid.stroke()

        NSColor.labelColor.withAlphaComponent(0.38).setStroke()
        let leftFold = NSBezierPath()
        leftFold.move(to: NSPoint(x: 6.2, y: 13.1))
        leftFold.curve(
            to: NSPoint(x: 17.0, y: 12.4),
            controlPoint1: NSPoint(x: 9.6, y: 14.7),
            controlPoint2: NSPoint(x: 13.4, y: 14.3)
        )
        leftFold.lineWidth = 0.9
        leftFold.lineCapStyle = .round
        leftFold.stroke()

        let rightFold = NSBezierPath()
        rightFold.move(to: NSPoint(x: 21.0, y: 12.4))
        rightFold.curve(
            to: NSPoint(x: 31.8, y: 13.1),
            controlPoint1: NSPoint(x: 24.6, y: 14.3),
            controlPoint2: NSPoint(x: 28.4, y: 14.7)
        )
        rightFold.lineWidth = 0.9
        rightFold.lineCapStyle = .round
        rightFold.stroke()

        drawTiredLines()
        drawSleepingZs(phase: sleepingPhase)
    }

    private static func drawBusy(in rect: NSRect) {
        drawOpenEyes(in: rect)

        NSColor.systemGreen.withAlphaComponent(0.9).setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 5, y: 2.5))
        path.curve(
            to: NSPoint(x: 25, y: 2.5),
            controlPoint1: NSPoint(x: 10, y: 0.5),
            controlPoint2: NSPoint(x: 20, y: 0.5)
        )
        path.lineWidth = 1.4
        path.stroke()
    }

    private static func drawBlink(in rect: NSRect) {
        let stroke = NSColor.labelColor
        let fill = NSColor.controlBackgroundColor
        let left = NSRect(x: 4.5, y: 5.2, width: 14.5, height: 11)
        let right = NSRect(x: 19, y: 5.2, width: 14.5, height: 11)

        for eye in [left, right] {
            let path = NSBezierPath(ovalIn: eye)
            fill.setFill()
            path.fill()
            stroke.setStroke()
            path.lineWidth = 1.45
            path.stroke()
        }

        drawBrows(enabled: true)

        stroke.setStroke()
        for x in [4.5, 19] {
            let lid = NSBezierPath()
            lid.move(to: NSPoint(x: x, y: 10.4))
            lid.curve(
                to: NSPoint(x: x + 14.5, y: 10.4),
                controlPoint1: NSPoint(x: x + 4, y: 8.8),
                controlPoint2: NSPoint(x: x + 10.5, y: 8.8)
            )
            lid.lineWidth = 2
            lid.stroke()
        }
    }

    private static func drawTiredLines() {
        NSColor.labelColor.withAlphaComponent(0.55).setStroke()

        let underLines = [
            (NSPoint(x: 7.0, y: 3.2), NSPoint(x: 17.0, y: 3.4), NSPoint(x: 9.4, y: 1.6), NSPoint(x: 14.4, y: 1.9)),
            (NSPoint(x: 21.0, y: 3.5), NSPoint(x: 31.2, y: 3.1), NSPoint(x: 23.6, y: 1.9), NSPoint(x: 28.5, y: 1.5)),
            (NSPoint(x: 8.7, y: 1.2), NSPoint(x: 15.8, y: 1.3), NSPoint(x: 10.6, y: 0.4), NSPoint(x: 13.8, y: 0.4)),
            (NSPoint(x: 22.6, y: 1.3), NSPoint(x: 29.6, y: 1.1), NSPoint(x: 24.5, y: 0.4), NSPoint(x: 27.6, y: 0.3)),
        ]

        for line in underLines {
            let path = NSBezierPath()
            path.move(to: line.0)
            path.curve(to: line.1, controlPoint1: line.2, controlPoint2: line.3)
            path.lineWidth = line.0.y > 2 ? 0.95 : 0.75
            path.lineCapStyle = .round
            path.stroke()
        }

        let outerLines = [
            (NSPoint(x: 3.7, y: 7.7), NSPoint(x: 0.7, y: 6.9)),
            (NSPoint(x: 3.6, y: 5.7), NSPoint(x: 0.7, y: 5.0)),
            (NSPoint(x: 3.9, y: 3.9), NSPoint(x: 1.4, y: 2.7)),
            (NSPoint(x: 34.3, y: 7.5), NSPoint(x: 37.1, y: 6.2)),
            (NSPoint(x: 34.4, y: 5.5), NSPoint(x: 37.2, y: 4.8)),
            (NSPoint(x: 34.1, y: 3.9), NSPoint(x: 36.4, y: 2.5)),
        ]

        for line in outerLines {
            let path = NSBezierPath()
            path.move(to: line.0)
            path.line(to: line.1)
            path.lineWidth = 0.85
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    private static func drawSleepingZs(phase: Int) {
        let strings = ["Z", "z", "z"]
        let positions = [
            NSPoint(x: 27.0, y: 13.8),
            NSPoint(x: 30.2, y: 16.7),
            NSPoint(x: 32.5, y: 18.7),
        ]

        for index in strings.indices {
            let age = (index + phase) % strings.count
            let alpha = [0.55, 0.82, 1.0][age]
            let size: CGFloat = [5.8, 6.8, 7.8][age]
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: size),
                .foregroundColor: NSColor.labelColor.withAlphaComponent(alpha),
            ]
            strings[index].draw(at: positions[index], withAttributes: attributes)
        }
    }

    private static func sleepLidColor() -> NSColor {
        NSColor(red: 0.87, green: 0.83, blue: 0.75, alpha: 0.98)
    }

    private static func drawBrows(enabled: Bool) {
        NSColor.labelColor.setStroke()

        if enabled {
            let left = NSBezierPath()
            left.move(to: NSPoint(x: 4.2, y: 19.0))
            left.curve(
                to: NSPoint(x: 17.0, y: 18.2),
                controlPoint1: NSPoint(x: 7.8, y: 21.2),
                controlPoint2: NSPoint(x: 12.5, y: 21.6)
            )
            left.lineWidth = 2.0
            left.lineCapStyle = .round
            left.stroke()

            let right = NSBezierPath()
            right.move(to: NSPoint(x: 21.0, y: 18.2))
            right.curve(
                to: NSPoint(x: 33.8, y: 19.0),
                controlPoint1: NSPoint(x: 25.5, y: 21.6),
                controlPoint2: NSPoint(x: 30.2, y: 21.2)
            )
            right.lineWidth = 2.0
            right.lineCapStyle = .round
            right.stroke()
        } else {
            let left = NSBezierPath()
            left.move(to: NSPoint(x: 5.0, y: 17.2))
            left.curve(
                to: NSPoint(x: 17.2, y: 15.2),
                controlPoint1: NSPoint(x: 9.0, y: 18.5),
                controlPoint2: NSPoint(x: 13.0, y: 17.8)
            )
            left.lineWidth = 1.8
            left.lineCapStyle = .round
            left.stroke()

            let right = NSBezierPath()
            right.move(to: NSPoint(x: 20.8, y: 15.2))
            right.curve(
                to: NSPoint(x: 33.0, y: 17.2),
                controlPoint1: NSPoint(x: 25.0, y: 17.8),
                controlPoint2: NSPoint(x: 29.0, y: 18.5)
            )
            right.lineWidth = 1.8
            right.lineCapStyle = .round
            right.stroke()
        }
    }
}
