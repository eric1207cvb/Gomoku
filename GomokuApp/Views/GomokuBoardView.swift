import SwiftUI

struct GomokuBoardView: View {
    let board: GomokuBoard
    let lastMove: Move?
    let winningLine: [Move]
    let hintMoves: [Move]
    let aiHighlightedMove: Move?
    let canTap: Bool
    let onTap: (Move) -> Void

    var body: some View {
        GeometryReader { proxy in
            Group {
                if aiHighlightedMove != nil {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        boardCanvas(animationPhase: timeline.date.timeIntervalSinceReferenceDate)
                    }
                } else {
                    boardCanvas(animationPhase: 0)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        guard canTap, let move = move(at: value.location, in: proxy.size) else { return }
                        onTap(move)
                    }
            )
            .accessibilityLabel("五子棋棋盤")
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func boardCanvas(animationPhase: TimeInterval) -> some View {
        Canvas { context, size in
            drawBoard(
                context: context,
                size: size,
                animationPhase: animationPhase
            )
        }
    }

    private func drawBoard(context: GraphicsContext, size: CGSize, animationPhase: TimeInterval) {
        let metrics = boardMetrics(in: size)
        let boardRect = CGRect(
            x: metrics.origin.x + metrics.cell * 0.28,
            y: metrics.origin.y + metrics.cell * 0.28,
            width: metrics.side - metrics.cell * 0.56,
            height: metrics.side - metrics.cell * 0.56
        )

        let background = Gradient(colors: [
            Color(red: 1.00, green: 0.88, blue: 0.45),
            Color(red: 1.00, green: 0.68, blue: 0.47),
            Color(red: 0.98, green: 0.48, blue: 0.56)
        ])
        let boardPath = Path(roundedRect: boardRect, cornerRadius: 8)

        context.drawLayer { layer in
            layer.addFilter(.shadow(color: Color(red: 0.55, green: 0.21, blue: 0.34).opacity(0.20), radius: metrics.cell * 0.30, x: 0, y: metrics.cell * 0.18))
            layer.fill(
                boardPath,
                with: .linearGradient(background, startPoint: boardRect.origin, endPoint: CGPoint(x: boardRect.maxX, y: boardRect.maxY))
            )
        }
        context.stroke(boardPath, with: .color(.white.opacity(0.75)), lineWidth: max(2, metrics.cell * 0.08))

        drawGrid(context: context, metrics: metrics)
        drawStarPoints(context: context, metrics: metrics)
        drawMoveHints(context: context, metrics: metrics)
        drawAIHighlight(context: context, metrics: metrics, animationPhase: animationPhase)
        drawWinningLine(context: context, metrics: metrics)
        drawStones(context: context, metrics: metrics)
    }

    private func drawGrid(context: GraphicsContext, metrics: BoardMetrics) {
        var path = Path()
        let start = metrics.gridStart
        let end = metrics.gridEnd

        for index in 0..<board.size {
            let offset = CGFloat(index) * metrics.cell
            path.move(to: CGPoint(x: start.x, y: start.y + offset))
            path.addLine(to: CGPoint(x: end.x, y: start.y + offset))
            path.move(to: CGPoint(x: start.x + offset, y: start.y))
            path.addLine(to: CGPoint(x: start.x + offset, y: end.y))
        }

        context.stroke(
            path,
            with: .color(Color(red: 0.32, green: 0.18, blue: 0.20).opacity(0.58)),
            lineWidth: max(1, metrics.cell * 0.034)
        )
    }

    private func drawStarPoints(context: GraphicsContext, metrics: BoardMetrics) {
        let points = [3, 7, 11]
        for row in points {
            for column in points {
                let center = center(for: Move(row: row, column: column), metrics: metrics)
                let radius = max(3.2, metrics.cell * 0.12)
                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(Color(red: 1.00, green: 0.96, blue: 0.58).opacity(0.98))
                )
                context.stroke(
                    Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(Color(red: 0.51, green: 0.22, blue: 0.18).opacity(0.42)),
                    lineWidth: max(1, metrics.cell * 0.025)
                )
            }
        }
    }

    private func drawMoveHints(context: GraphicsContext, metrics: BoardMetrics) {
        for move in hintMoves.prefix(3) where board[move] == nil {
            let center = center(for: move, metrics: metrics)
            let radius = metrics.cell * 0.34
            let innerRadius = radius * 0.58
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

            context.drawLayer { layer in
                layer.addFilter(.shadow(color: Color(red: 0.40, green: 0.22, blue: 0.36).opacity(0.18), radius: metrics.cell * 0.08, x: 0, y: metrics.cell * 0.04))
                layer.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        Gradient(colors: [
                            .white.opacity(0.62),
                            Color(red: 0.62, green: 0.92, blue: 0.82).opacity(0.46),
                            Color(red: 0.96, green: 0.45, blue: 0.62).opacity(0.24)
                        ]),
                        center: center,
                        startRadius: 1,
                        endRadius: radius * 1.12
                    )
                )
                layer.stroke(
                    Path(ellipseIn: rect.insetBy(dx: radius * 0.04, dy: radius * 0.04)),
                    with: .color(.white.opacity(0.78)),
                    lineWidth: max(1.2, metrics.cell * 0.035)
                )
                layer.stroke(
                    Path(ellipseIn: CGRect(x: center.x - innerRadius, y: center.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2)),
                    with: .color(Color(red: 0.34, green: 0.79, blue: 0.66).opacity(0.34)),
                    lineWidth: max(1, metrics.cell * 0.026)
                )
            }
        }
    }

    private func drawAIHighlight(context: GraphicsContext, metrics: BoardMetrics, animationPhase: TimeInterval) {
        guard let aiHighlightedMove, board[aiHighlightedMove] != nil else { return }

        let center = center(for: aiHighlightedMove, metrics: metrics)
        let pulse = (sin(animationPhase * 4.2) + 1) / 2
        let radius = metrics.cell * (0.58 + CGFloat(pulse) * 0.08)
        let outerRadius = radius * 1.22
        let outerRect = CGRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        )
        let ringRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let sky = Color(red: 0.30, green: 0.67, blue: 0.94)
        let mint = Color(red: 0.27, green: 0.78, blue: 0.62)

        context.drawLayer { layer in
            layer.addFilter(.shadow(color: sky.opacity(0.22), radius: metrics.cell * 0.20, x: 0, y: 0))
            layer.fill(
                Path(ellipseIn: outerRect),
                with: .radialGradient(
                    Gradient(colors: [
                        sky.opacity(0.28),
                        mint.opacity(0.14),
                        Color.white.opacity(0.02)
                    ]),
                    center: center,
                    startRadius: 1,
                    endRadius: outerRadius
                )
            )
            layer.stroke(
                Path(ellipseIn: ringRect),
                with: .color(.white.opacity(0.96)),
                lineWidth: max(2.2, metrics.cell * 0.06)
            )
            layer.stroke(
                Path(ellipseIn: ringRect.insetBy(dx: -metrics.cell * 0.08, dy: -metrics.cell * 0.08)),
                with: .color(sky.opacity(0.70)),
                lineWidth: max(1.6, metrics.cell * 0.045)
            )
        }
    }

    private func drawWinningLine(context: GraphicsContext, metrics: BoardMetrics) {
        guard let first = winningLine.first, let last = winningLine.last else { return }

        var path = Path()
        path.move(to: center(for: first, metrics: metrics))
        path.addLine(to: center(for: last, metrics: metrics))
        let width = max(5, metrics.cell * 0.16)
        context.stroke(path, with: .color(Color(red: 1.00, green: 0.86, blue: 0.18).opacity(0.32)), style: StrokeStyle(lineWidth: width + 12, lineCap: .round))
        context.stroke(path, with: .color(.white.opacity(0.96)), style: StrokeStyle(lineWidth: width + 5, lineCap: .round))
        context.stroke(path, with: .color(Color(red: 1.00, green: 0.76, blue: 0.18)), style: StrokeStyle(lineWidth: width + 1.5, lineCap: .round))
        context.stroke(path, with: .color(Color(red: 0.92, green: 0.18, blue: 0.48)), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func drawStones(context: GraphicsContext, metrics: BoardMetrics) {
        let radius = metrics.cell * 0.40
        let winningMoves = Set(winningLine)

        for move in board.occupiedMoves {
            guard let stone = board[move] else { continue }
            let center = center(for: move, metrics: metrics)
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            let isWinningStone = winningMoves.contains(move)

            if isWinningStone {
                drawWinningStoneGlow(context: context, center: center, radius: radius, metrics: metrics)
            }

            context.drawLayer { layer in
                layer.addFilter(.shadow(color: .black.opacity(0.22), radius: metrics.cell * 0.08, x: 0, y: metrics.cell * 0.06))
                let gradient = stoneGradient(stone: stone, center: center, radius: radius)
                layer.fill(Path(ellipseIn: rect), with: gradient)
                layer.stroke(
                    Path(ellipseIn: rect.insetBy(dx: radius * 0.04, dy: radius * 0.04)),
                    with: .color(stone == .black ? .white.opacity(0.12) : Color(red: 1.0, green: 0.73, blue: 0.55).opacity(0.54)),
                    lineWidth: max(1, metrics.cell * 0.035)
                )
            }

            drawStoneHighlight(context: context, stone: stone, center: center, radius: radius)
            drawStoneFace(context: context, stone: stone, center: center, radius: radius)

            if isWinningStone {
                drawWinningStoneSparkle(context: context, center: center, radius: radius, metrics: metrics)
            }

            if lastMove == move {
                drawLastMoveCandyMark(context: context, center: center, radius: radius, metrics: metrics)
            }
        }
    }

    private func drawLastMoveCandyMark(context: GraphicsContext, center: CGPoint, radius: CGFloat, metrics: BoardMetrics) {
        let glowRadius = radius * 1.18
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - glowRadius, y: center.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2)),
            with: .radialGradient(
                Gradient(colors: [
                    Color(red: 1.00, green: 0.88, blue: 0.28).opacity(0.38),
                    Color(red: 1.00, green: 0.37, blue: 0.56).opacity(0.05)
                ]),
                center: center,
                startRadius: 1,
                endRadius: glowRadius
            )
        )

        context.stroke(
            Path(ellipseIn: CGRect(x: center.x - glowRadius, y: center.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2)),
            with: .color(Color(red: 1.00, green: 0.93, blue: 0.58).opacity(0.92)),
            lineWidth: max(2.2, metrics.cell * 0.05)
        )

        let starCenter = CGPoint(x: center.x + radius * 0.72, y: center.y - radius * 0.76)
        drawSparkle(context: context, center: starCenter, radius: max(3.2, metrics.cell * 0.11), color: Color(red: 1.00, green: 0.79, blue: 0.22))

        let heartCenter = CGPoint(x: center.x - radius * 0.78, y: center.y + radius * 0.72)
        drawHeart(context: context, center: heartCenter, radius: max(3.6, metrics.cell * 0.12), color: Color(red: 1.00, green: 0.36, blue: 0.52).opacity(0.86))
    }

    private func drawSparkle(context: GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        var sparkle = Path()
        sparkle.move(to: CGPoint(x: center.x, y: center.y - radius))
        sparkle.addLine(to: CGPoint(x: center.x + radius * 0.28, y: center.y - radius * 0.28))
        sparkle.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        sparkle.addLine(to: CGPoint(x: center.x + radius * 0.28, y: center.y + radius * 0.28))
        sparkle.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        sparkle.addLine(to: CGPoint(x: center.x - radius * 0.28, y: center.y + radius * 0.28))
        sparkle.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        sparkle.addLine(to: CGPoint(x: center.x - radius * 0.28, y: center.y - radius * 0.28))
        sparkle.closeSubpath()

        context.fill(sparkle, with: .color(color.opacity(0.96)))
        context.stroke(sparkle, with: .color(.white.opacity(0.82)), lineWidth: max(1, radius * 0.16))
    }

    private func drawHeart(context: GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        var heart = Path()
        heart.move(to: CGPoint(x: center.x, y: center.y + radius * 0.72))
        heart.addCurve(
            to: CGPoint(x: center.x - radius, y: center.y - radius * 0.10),
            control1: CGPoint(x: center.x - radius * 0.54, y: center.y + radius * 0.34),
            control2: CGPoint(x: center.x - radius, y: center.y + radius * 0.30)
        )
        heart.addCurve(
            to: CGPoint(x: center.x, y: center.y - radius * 0.36),
            control1: CGPoint(x: center.x - radius, y: center.y - radius * 0.72),
            control2: CGPoint(x: center.x - radius * 0.28, y: center.y - radius * 0.74)
        )
        heart.addCurve(
            to: CGPoint(x: center.x + radius, y: center.y - radius * 0.10),
            control1: CGPoint(x: center.x + radius * 0.28, y: center.y - radius * 0.74),
            control2: CGPoint(x: center.x + radius, y: center.y - radius * 0.72)
        )
        heart.addCurve(
            to: CGPoint(x: center.x, y: center.y + radius * 0.72),
            control1: CGPoint(x: center.x + radius, y: center.y + radius * 0.30),
            control2: CGPoint(x: center.x + radius * 0.54, y: center.y + radius * 0.34)
        )
        heart.closeSubpath()

        context.fill(heart, with: .color(color))
        context.stroke(heart, with: .color(.white.opacity(0.76)), lineWidth: max(1, radius * 0.15))
    }

    private func drawWinningStoneGlow(context: GraphicsContext, center: CGPoint, radius: CGFloat, metrics: BoardMetrics) {
        let outerRadius = radius * 1.34
        let middleRadius = radius * 1.12
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - outerRadius, y: center.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2)),
            with: .radialGradient(
                Gradient(colors: [
                    Color(red: 1.00, green: 0.87, blue: 0.20).opacity(0.50),
                    Color(red: 1.00, green: 0.42, blue: 0.58).opacity(0.04)
                ]),
                center: center,
                startRadius: 1,
                endRadius: outerRadius
            )
        )
        context.stroke(
            Path(ellipseIn: CGRect(x: center.x - middleRadius, y: center.y - middleRadius, width: middleRadius * 2, height: middleRadius * 2)),
            with: .color(.white.opacity(0.92)),
            lineWidth: max(2, metrics.cell * 0.055)
        )
        context.stroke(
            Path(ellipseIn: CGRect(x: center.x - outerRadius, y: center.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2)),
            with: .color(Color(red: 1.00, green: 0.78, blue: 0.24).opacity(0.78)),
            lineWidth: max(2, metrics.cell * 0.045)
        )
    }

    private func drawWinningStoneSparkle(context: GraphicsContext, center: CGPoint, radius: CGFloat, metrics: BoardMetrics) {
        let sparkleRadius = max(2, metrics.cell * 0.09)
        let positions = [
            CGPoint(x: center.x - radius * 0.94, y: center.y - radius * 0.92),
            CGPoint(x: center.x + radius * 0.94, y: center.y - radius * 0.72),
            CGPoint(x: center.x + radius * 0.78, y: center.y + radius * 0.90)
        ]

        for (index, point) in positions.enumerated() {
            let length = sparkleRadius * (index == 0 ? 2.15 : 1.65)
            var path = Path()
            path.move(to: CGPoint(x: point.x, y: point.y - length))
            path.addLine(to: CGPoint(x: point.x, y: point.y + length))
            path.move(to: CGPoint(x: point.x - length, y: point.y))
            path.addLine(to: CGPoint(x: point.x + length, y: point.y))
            context.stroke(
                path,
                with: .color(index == 1 ? Color.white.opacity(0.94) : Color(red: 1.00, green: 0.86, blue: 0.20).opacity(0.95)),
                style: StrokeStyle(lineWidth: max(1.4, metrics.cell * 0.035), lineCap: .round)
            )
        }
    }

    private func stoneGradient(stone: Stone, center: CGPoint, radius: CGFloat) -> GraphicsContext.Shading {
        switch stone {
        case .black:
            .radialGradient(
                Gradient(colors: [
                    Color(red: 0.43, green: 0.41, blue: 0.48),
                    Color(red: 0.07, green: 0.07, blue: 0.10)
                ]),
                center: CGPoint(x: center.x - radius * 0.28, y: center.y - radius * 0.35),
                startRadius: 1,
                endRadius: radius * 1.2
            )
        case .white:
            .radialGradient(
                Gradient(colors: [
                    Color.white,
                    Color(red: 1.00, green: 0.91, blue: 0.76)
                ]),
                center: CGPoint(x: center.x - radius * 0.25, y: center.y - radius * 0.35),
                startRadius: 1,
                endRadius: radius * 1.15
            )
        }
    }

    private func drawStoneHighlight(context: GraphicsContext, stone: Stone, center: CGPoint, radius: CGFloat) {
        let highlight = CGRect(
            x: center.x - radius * 0.42,
            y: center.y - radius * 0.48,
            width: radius * 0.42,
            height: radius * 0.28
        )
        context.fill(
            Path(ellipseIn: highlight),
            with: .color((stone == .black ? Color.white : Color(red: 1.0, green: 0.98, blue: 0.90)).opacity(stone == .black ? 0.34 : 0.72))
        )

        let sparkleRadius = max(1.2, radius * 0.10)
        let sparkleCenter = CGPoint(x: center.x + radius * 0.28, y: center.y - radius * 0.28)
        context.fill(
            Path(ellipseIn: CGRect(x: sparkleCenter.x - sparkleRadius, y: sparkleCenter.y - sparkleRadius, width: sparkleRadius * 2, height: sparkleRadius * 2)),
            with: .color(.white.opacity(stone == .black ? 0.46 : 0.84))
        )
    }

    private func drawStoneFace(context: GraphicsContext, stone: Stone, center: CGPoint, radius: CGFloat) {
        guard radius >= 11 else { return }

        let faceColor = stone == .black
            ? Color.white.opacity(0.86)
            : Color(red: 0.24, green: 0.13, blue: 0.13).opacity(0.88)
        let cheekColor = Color(red: 1.00, green: 0.38, blue: 0.47).opacity(stone == .black ? 0.78 : 0.55)
        let eyeRadius = max(1.4, radius * 0.08)
        let cheekRadius = max(1.8, radius * 0.10)

        for xOffset in [-radius * 0.26, radius * 0.26] {
            let eyeCenter = CGPoint(x: center.x + xOffset, y: center.y - radius * 0.08)
            context.fill(
                Path(ellipseIn: CGRect(x: eyeCenter.x - eyeRadius, y: eyeCenter.y - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2)),
                with: .color(faceColor)
            )
        }

        for xOffset in [-radius * 0.44, radius * 0.44] {
            let cheekCenter = CGPoint(x: center.x + xOffset, y: center.y + radius * 0.14)
            context.fill(
                Path(ellipseIn: CGRect(x: cheekCenter.x - cheekRadius, y: cheekCenter.y - cheekRadius, width: cheekRadius * 2, height: cheekRadius * 1.35)),
                with: .color(cheekColor)
            )
        }

        var smile = Path()
        smile.move(to: CGPoint(x: center.x - radius * 0.14, y: center.y + radius * 0.15))
        smile.addQuadCurve(
            to: CGPoint(x: center.x + radius * 0.14, y: center.y + radius * 0.15),
            control: CGPoint(x: center.x, y: center.y + radius * 0.30)
        )
        context.stroke(
            smile,
            with: .color(faceColor),
            style: StrokeStyle(lineWidth: max(1.4, radius * 0.09), lineCap: .round)
        )
    }

    private func move(at location: CGPoint, in size: CGSize) -> Move? {
        let metrics = boardMetrics(in: size)
        let column = Int(round((location.x - metrics.gridStart.x) / metrics.cell))
        let row = Int(round((location.y - metrics.gridStart.y) / metrics.cell))
        let move = Move(row: row, column: column)

        guard board.contains(move) else { return nil }

        let center = center(for: move, metrics: metrics)
        let distance = hypot(location.x - center.x, location.y - center.y)
        return distance <= metrics.cell * 0.48 ? move : nil
    }

    private func center(for move: Move, metrics: BoardMetrics) -> CGPoint {
        CGPoint(
            x: metrics.gridStart.x + CGFloat(move.column) * metrics.cell,
            y: metrics.gridStart.y + CGFloat(move.row) * metrics.cell
        )
    }

    private func boardMetrics(in size: CGSize) -> BoardMetrics {
        let side = min(size.width, size.height)
        let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
        let cell = side / (CGFloat(board.size) + 0.15)
        let gridStart = CGPoint(x: origin.x + cell * 0.58, y: origin.y + cell * 0.58)
        let gridEnd = CGPoint(
            x: gridStart.x + CGFloat(board.size - 1) * cell,
            y: gridStart.y + CGFloat(board.size - 1) * cell
        )
        return BoardMetrics(side: side, origin: origin, cell: cell, gridStart: gridStart, gridEnd: gridEnd)
    }
}

private struct BoardMetrics {
    let side: CGFloat
    let origin: CGPoint
    let cell: CGFloat
    let gridStart: CGPoint
    let gridEnd: CGPoint
}
