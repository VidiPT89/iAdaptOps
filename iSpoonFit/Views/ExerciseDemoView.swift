import SwiftUI

/// A looping stick-figure animation of one exercise, drawn entirely in code.
/// There are no video or image assets anywhere in the app, which is what keeps
/// the whole catalog offline and weightless.
struct ExerciseDemoView: View {
    let motion: ExerciseMotionKind
    var lineWidth: CGFloat = 5
    var cycleDuration: Double = 2.0
    var showsBottles: Bool = false
    var showsArrows: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let theme = Theme.shared

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let pose = reduceMotion
                    ? ExerciseMotionPose.keyPose(for: motion)
                    : ExerciseMotionPose.pose(for: motion, phase: phase(at: timeline.date))
                draw(pose, in: &context, size: size)
            }
        }
        .accessibilityHidden(true)
    }

    private func phase(at date: Date) -> Double {
        let duration = max(0.2, cycleDuration)
        return date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: duration) / duration
    }

    // MARK: - Drawing

    private func draw(_ pose: StickPose, in context: inout GraphicsContext, size: CGSize) {
        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x * size.width, y: p.y * size.height)
        }

        let scale = min(size.width, size.height)
        let groundY = size.height * (pose.horizontal ? 0.90 : 0.945)

        drawFloor(&context, size: size, groundY: groundY, usesMat: motion.usesMat)
        if let prop = motion.prop {
            drawProp(prop, pose: pose, in: &context, size: size, groundY: groundY, point: point)
        }
        drawShadow(&context, pose: pose, size: size, groundY: groundY, point: point)

        if pose.breathing > 0 {
            drawBreathingGlow(&context, pose: pose, scale: scale, point: point)
        }

        if showsArrows {
            for arrow in pose.arrows {
                drawArrow(from: point(arrow.from), to: point(arrow.to), in: &context, scale: scale)
            }
        }

        var limbs = Path()
        limbs.move(to: point(pose.neck)); limbs.addLine(to: point(pose.hip))
        limbs.move(to: point(pose.neck)); limbs.addLine(to: point(pose.elbowL)); limbs.addLine(to: point(pose.handL))
        limbs.move(to: point(pose.neck)); limbs.addLine(to: point(pose.elbowR)); limbs.addLine(to: point(pose.handR))
        limbs.move(to: point(pose.hip)); limbs.addLine(to: point(pose.kneeL)); limbs.addLine(to: point(pose.footL))
        limbs.move(to: point(pose.hip)); limbs.addLine(to: point(pose.kneeR)); limbs.addLine(to: point(pose.footR))

        context.stroke(
            limbs,
            with: bodyShading(size: size),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )

        let headRadius = scale * 0.072
        let head = point(pose.head)
        context.fill(
            Path(ellipseIn: CGRect(
                x: head.x - headRadius, y: head.y - headRadius,
                width: headRadius * 2, height: headRadius * 2
            )),
            with: .color(theme.accent)
        )

        if showsBottles {
            drawBottle(at: point(pose.handL), in: &context, scale: scale)
            drawBottle(at: point(pose.handR), in: &context, scale: scale)
        }
    }

    private func bodyShading(size: CGSize) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(colors: [theme.accentLight, theme.accent, theme.accentDark]),
            startPoint: .zero,
            endPoint: CGPoint(x: size.width, y: size.height)
        )
    }

    private func drawFloor(_ context: inout GraphicsContext, size: CGSize, groundY: CGFloat, usesMat: Bool) {
        if usesMat {
            let mat = CGRect(
                x: size.width * 0.03,
                y: groundY - size.height * 0.008,
                width: size.width * 0.94,
                height: size.height * 0.055
            )
            context.fill(
                Path(roundedRect: mat, cornerRadius: mat.height / 2),
                with: .color(theme.panel2)
            )
            context.stroke(
                Path(roundedRect: mat, cornerRadius: mat.height / 2),
                with: .color(theme.accent.opacity(0.18)),
                lineWidth: 1
            )
        } else {
            var line = Path()
            line.move(to: CGPoint(x: size.width * 0.08, y: groundY))
            line.addLine(to: CGPoint(x: size.width * 0.92, y: groundY))
            context.stroke(
                line,
                with: .color(theme.textFaint.opacity(0.35)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
        }
    }

    private func drawShadow(
        _ context: inout GraphicsContext,
        pose: StickPose,
        size: CGSize,
        groundY: CGFloat,
        point: (CGPoint) -> CGPoint
    ) {
        let center = point(pose.hip).x
        let width = size.width * (pose.horizontal ? 0.52 : 0.26)
        let rect = CGRect(
            x: center - width / 2,
            y: groundY - size.height * 0.012,
            width: width,
            height: size.height * 0.026
        )
        context.fill(Path(ellipseIn: rect), with: .color(theme.accent.opacity(0.12)))
    }

    private func drawBreathingGlow(
        _ context: inout GraphicsContext,
        pose: StickPose,
        scale: CGFloat,
        point: (CGPoint) -> CGPoint
    ) {
        let center = point(CGPoint(
            x: (pose.neck.x + pose.hip.x) / 2,
            y: (pose.neck.y + pose.hip.y) / 2
        ))
        let radius = scale * (0.13 + 0.05 * pose.breathing)
        let rect = CGRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        )
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [
                    theme.accent.opacity(0.22 * (0.5 + pose.breathing / 2)),
                    theme.accent.opacity(0)
                ]),
                center: center,
                startRadius: 0,
                endRadius: radius
            )
        )
    }

    private func drawArrow(from: CGPoint, to: CGPoint, in context: inout GraphicsContext, scale: CGFloat) {
        var shaft = Path()
        shaft.move(to: from)
        shaft.addLine(to: to)
        let color = theme.accent.opacity(0.45)
        context.stroke(shaft, with: .color(color), style: StrokeStyle(lineWidth: lineWidth * 0.45, lineCap: .round))

        let angle = atan2(to.y - from.y, to.x - from.x)
        let headLength = scale * 0.045
        var head = Path()
        head.move(to: to)
        head.addLine(to: CGPoint(
            x: to.x - headLength * cos(angle - .pi / 7),
            y: to.y - headLength * sin(angle - .pi / 7)
        ))
        head.addLine(to: CGPoint(
            x: to.x - headLength * cos(angle + .pi / 7),
            y: to.y - headLength * sin(angle + .pi / 7)
        ))
        head.closeSubpath()
        context.fill(head, with: .color(color))
    }

    private func drawBottle(at point: CGPoint, in context: inout GraphicsContext, scale: CGFloat) {
        let width = scale * 0.045
        let height = scale * 0.085
        let body = CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height)
        context.fill(
            Path(roundedRect: body, cornerRadius: width * 0.3),
            with: .color(theme.rest.opacity(0.75))
        )
        let cap = CGRect(x: point.x - width * 0.18, y: body.minY - height * 0.16, width: width * 0.36, height: height * 0.18)
        context.fill(Path(roundedRect: cap, cornerRadius: 1.5), with: .color(theme.rest))
    }

    private func drawProp(
        _ prop: ExerciseProp,
        pose: StickPose,
        in context: inout GraphicsContext,
        size: CGSize,
        groundY: CGFloat,
        point: (CGPoint) -> CGPoint
    ) {
        let color = theme.textFaint.opacity(0.35)
        switch prop {
        case .wall:
            let rect = CGRect(
                x: size.width * 0.235,
                y: size.height * 0.12,
                width: size.width * 0.035,
                height: groundY - size.height * 0.12
            )
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(color))

        case .chair:
            var chair = Path()
            let seatY = size.height * 0.60
            let left = size.width * 0.66
            let right = size.width * 0.86
            chair.move(to: CGPoint(x: left, y: seatY))
            chair.addLine(to: CGPoint(x: right, y: seatY))
            chair.move(to: CGPoint(x: right, y: seatY))
            chair.addLine(to: CGPoint(x: right, y: size.height * 0.36))
            chair.move(to: CGPoint(x: left, y: seatY))
            chair.addLine(to: CGPoint(x: left, y: groundY))
            chair.move(to: CGPoint(x: right, y: seatY))
            chair.addLine(to: CGPoint(x: right, y: groundY))
            context.stroke(chair, with: .color(color), style: StrokeStyle(lineWidth: lineWidth * 0.6, lineCap: .round))

        case .seat:
            // Side view: seat just under the hip, backrest behind the back.
            var seat = Path()
            let seatY = size.height * 0.63
            let back = size.width * 0.33
            let front = size.width * 0.56
            seat.move(to: CGPoint(x: back, y: size.height * 0.36))
            seat.addLine(to: CGPoint(x: back, y: groundY))
            seat.move(to: CGPoint(x: back, y: seatY))
            seat.addLine(to: CGPoint(x: front, y: seatY))
            seat.addLine(to: CGPoint(x: front, y: groundY))
            context.stroke(seat, with: .color(color), style: StrokeStyle(lineWidth: lineWidth * 0.6, lineCap: .round, lineJoin: .round))

        case .seatFront:
            // Front view: the seat edge and the two front legs.
            var seat = Path()
            let seatY = size.height * 0.63
            let left = size.width * 0.36
            let right = size.width * 0.64
            seat.move(to: CGPoint(x: left, y: seatY))
            seat.addLine(to: CGPoint(x: right, y: seatY))
            seat.move(to: CGPoint(x: left + 0.01 * size.width, y: seatY))
            seat.addLine(to: CGPoint(x: left + 0.01 * size.width, y: groundY))
            seat.move(to: CGPoint(x: right - 0.01 * size.width, y: seatY))
            seat.addLine(to: CGPoint(x: right - 0.01 * size.width, y: groundY))
            context.stroke(seat, with: .color(color), style: StrokeStyle(lineWidth: lineWidth * 0.6, lineCap: .round))

        case .towel:
            var towel = Path()
            towel.move(to: point(pose.handL))
            towel.addLine(to: point(pose.footR))
            towel.move(to: point(pose.handR))
            towel.addLine(to: point(pose.footR))
            context.stroke(
                towel,
                with: .color(theme.textDim.opacity(0.5)),
                style: StrokeStyle(lineWidth: lineWidth * 0.5, lineCap: .round, dash: [4, 4])
            )
        }
    }
}

/// Small looping preview shown next to an exercise name in a list.
struct ExerciseDemoThumbnail: View {
    let ref: ExerciseRef
    var size: CGFloat = 52
    var paceScale: Double = 1

    let theme = Theme.shared

    var body: some View {
        ExerciseDemoView(
            ref: ref,
            lineWidth: 2.4,
            showsArrows: false,
            paceScale: paceScale
        )
        .frame(width: size, height: size)
        .background(theme.panel2)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(theme.accent.opacity(0.10), lineWidth: 1)
        )
    }
}

extension ExerciseDemoView {
    /// Convenience initializer that reads the motion, the pace and whether to
    /// draw bottles straight from a day's exercise reference. `paceScale`
    /// above 1 slows the movement down, as on a low-energy day.
    init(ref: ExerciseRef, lineWidth: CGFloat = 5, showsArrows: Bool = true, paceScale: Double = 1) {
        self.init(
            motion: ref.motion,
            lineWidth: lineWidth,
            cycleDuration: paceScale * (ref.modifiers.isEmpty
                ? ref.motion.defaultCycleDuration
                : ref.animationCycleDuration),
            showsBottles: ref.modifiers.contains(.weighted),
            showsArrows: showsArrows
        )
    }
}
