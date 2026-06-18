import Foundation

public struct LocalGomokuAI: Sendable {
    private let difficulty: AIDifficulty

    public init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
    }

    public func bestMove(
        on board: GomokuBoard,
        for player: Stone,
        maximumThinkingTime: TimeInterval? = nil
    ) -> Move? {
        let deadline = maximumThinkingTime.map { Date().addingTimeInterval(max(0, $0)) }
        let ordered = orderedCandidates(
            on: board,
            for: player,
            limit: difficulty.candidateLimit,
            includesDoubleWinPressure: true,
            deadline: deadline
        )
        guard !ordered.isEmpty else { return nil }

        if let winningMove = immediateWinningMove(on: board, for: player, deadline: deadline) {
            return winningMove
        }

        if difficulty.blocksImmediateWins,
           let blockingMove = immediateWinningMove(on: board, for: player.opponent, deadline: deadline) {
            return blockingMove
        }

        if difficulty.prioritizesForcingThreats,
           let doubleWinMove = bestDoubleWinThreatMove(on: board, for: player, deadline: deadline) {
            return doubleWinMove.move
        }

        if difficulty.prioritizesForcingThreats,
           let doubleWinBlock = bestDoubleWinThreatMove(on: board, for: player.opponent, deadline: deadline) {
            return doubleWinBlock.move
        }

        if difficulty.prioritizesForcingThreats,
           let forcingMove = bestForcingThreatMove(on: board, for: player, deadline: deadline) {
            if let opponentThreat = bestForcingThreatMove(on: board, for: player.opponent, deadline: deadline),
               opponentThreat.profile.priority > forcingMove.profile.priority {
                return opponentThreat.move
            }
            return forcingMove.move
        }

        if difficulty.prioritizesForcingThreats,
           let blockingThreat = bestForcingThreatMove(on: board, for: player.opponent, deadline: deadline) {
            return blockingThreat.move
        }

        if difficulty.searchDepth == 0 {
            return relaxedChoice(from: ordered, board: board)
        }

        var bestMove = ordered[0]
        var bestScore = Int.min / 4
        var alpha = Int.min / 4
        let beta = Int.max / 4

        for move in ordered {
            if isExpired(deadline) {
                break
            }

            guard let next = try? board.placing(player, at: move) else { continue }
            let score = minimax(
                board: next,
                depth: difficulty.searchDepth - 1,
                currentPlayer: player.opponent,
                rootPlayer: player,
                alpha: alpha,
                beta: beta,
                deadline: deadline
            )

            if score > bestScore {
                bestScore = score
                bestMove = move
            }
            alpha = max(alpha, bestScore)
        }

        if difficulty.mistakeWindow > 1 {
            return relaxedChoice(from: ordered, board: board)
        }

        return bestMove
    }

    private func minimax(
        board: GomokuBoard,
        depth: Int,
        currentPlayer: Stone,
        rootPlayer: Stone,
        alpha: Int,
        beta: Int,
        deadline: Date?
    ) -> Int {
        guard !isExpired(deadline) else {
            return 0
        }

        switch board.outcome() {
        case .ongoing:
            break
        case .draw:
            return 0
        case let .win(winner, _):
            let base = winner == rootPlayer ? 10_000_000 : -10_000_000
            return base + (winner == rootPlayer ? depth : -depth)
        }

        if depth == 0 {
            return evaluate(board: board, for: rootPlayer, deadline: deadline)
        }

        let limit = max(8, difficulty.candidateLimit - (difficulty.searchDepth - depth) * 4)
        let candidates = orderedCandidates(
            on: board,
            for: currentPlayer,
            limit: limit,
            includesDoubleWinPressure: false,
            deadline: deadline
        )
        guard !candidates.isEmpty else { return 0 }

        if currentPlayer == rootPlayer {
            var value = Int.min / 4
            var localAlpha = alpha
            for move in candidates {
                if isExpired(deadline) {
                    break
                }

                guard let next = try? board.placing(currentPlayer, at: move) else { continue }
                value = max(
                    value,
                    minimax(
                        board: next,
                        depth: depth - 1,
                        currentPlayer: currentPlayer.opponent,
                        rootPlayer: rootPlayer,
                        alpha: localAlpha,
                        beta: beta,
                        deadline: deadline
                    )
                )
                localAlpha = max(localAlpha, value)
                if localAlpha >= beta {
                    break
                }
            }
            return value
        } else {
            var value = Int.max / 4
            var localBeta = beta
            for move in candidates {
                if isExpired(deadline) {
                    break
                }

                guard let next = try? board.placing(currentPlayer, at: move) else { continue }
                value = min(
                    value,
                    minimax(
                        board: next,
                        depth: depth - 1,
                        currentPlayer: currentPlayer.opponent,
                        rootPlayer: rootPlayer,
                        alpha: alpha,
                        beta: localBeta,
                        deadline: deadline
                    )
                )
                localBeta = min(localBeta, value)
                if alpha >= localBeta {
                    break
                }
            }
            return value
        }
    }

    private func orderedCandidates(
        on board: GomokuBoard,
        for player: Stone,
        limit: Int,
        includesDoubleWinPressure: Bool = false,
        deadline: Date? = nil
    ) -> [Move] {
        let candidates = board.candidateMoves(radius: difficulty.candidateRadius).sorted()
        var scored: [(move: Move, score: Int)] = []
        scored.reserveCapacity(min(limit, candidates.count))

        for move in candidates {
            if isExpired(deadline), !scored.isEmpty {
                break
            }

            scored.append((
                move: move,
                score: moveScore(
                    move,
                    on: board,
                    for: player,
                    includesDoubleWinPressure: includesDoubleWinPressure,
                    deadline: deadline
                )
            ))
        }

        guard !scored.isEmpty else {
            return Array(candidates.prefix(limit))
        }

        return scored
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.move < rhs.move
                }
                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map(\.move)
    }

    private func immediateWinningMove(on board: GomokuBoard, for player: Stone, deadline: Date? = nil) -> Move? {
        immediateWinningMoves(on: board, for: player, deadline: deadline).first
    }

    private func immediateWinningMoves(on board: GomokuBoard, for player: Stone, deadline: Date? = nil) -> [Move] {
        var moves: [Move] = []

        for move in board.candidateMoves(radius: 2).sorted() {
            if isExpired(deadline) {
                break
            }

            guard let next = try? board.placing(player, at: move) else { continue }
            if case .win = next.outcome(lastMove: move) {
                moves.append(move)
            }
        }

        return moves
    }

    private func bestDoubleWinThreatMove(
        on board: GomokuBoard,
        for player: Stone,
        deadline: Date? = nil
    ) -> ThreatCandidate? {
        var best: ThreatCandidate?

        for move in board.candidateMoves(radius: max(2, difficulty.candidateRadius)).sorted() {
            if isExpired(deadline) {
                break
            }

            guard let next = try? board.placing(player, at: move) else { continue }
            let winningReplies = immediateWinningMoves(on: next, for: player, deadline: deadline).count
            guard winningReplies >= 2 else { continue }

            let profile = threatProfile(at: move, on: board, for: player)
            let score = moveScore(move, on: board, for: player, deadline: deadline) + winningReplies * 90_000
            let candidate = ThreatCandidate(
                move: move,
                profile: profile.promoted(by: winningReplies),
                score: score
            )

            if best.map({ isBetterThreat(candidate, than: $0) }) ?? true {
                best = candidate
            }
        }

        return best
    }

    private func bestForcingThreatMove(
        on board: GomokuBoard,
        for player: Stone,
        deadline: Date? = nil
    ) -> ThreatCandidate? {
        var best: ThreatCandidate?

        for move in board.candidateMoves(radius: max(2, difficulty.candidateRadius)).sorted() {
            if isExpired(deadline) {
                break
            }

            var profile = threatProfile(at: move, on: board, for: player)
            var forcingReplyBonus = 0
            if let next = try? board.placing(player, at: move) {
                let winningReplies = immediateWinningMoves(on: next, for: player, deadline: deadline).count
                profile = profile.promoted(by: winningReplies)
                forcingReplyBonus = winningReplies * 90_000
            }
            guard profile.priority > 0 else { continue }

            let candidate = ThreatCandidate(
                move: move,
                profile: profile,
                score: moveScore(move, on: board, for: player, deadline: deadline) + forcingReplyBonus
            )

            if best.map({ isBetterThreat(candidate, than: $0) }) ?? true {
                best = candidate
            }
        }

        return best
    }

    private func isBetterThreat(_ lhs: ThreatCandidate, than rhs: ThreatCandidate) -> Bool {
        if lhs.profile.priority != rhs.profile.priority {
            return lhs.profile.priority > rhs.profile.priority
        }
        if lhs.score != rhs.score {
            return lhs.score > rhs.score
        }
        return lhs.move < rhs.move
    }

    private func relaxedChoice(from ordered: [Move], board: GomokuBoard) -> Move {
        let window = max(1, min(difficulty.mistakeWindow, ordered.count))
        let signature = UInt(bitPattern: board.boardSignature())
        return ordered[Int(signature % UInt(window))]
    }

    private func moveScore(
        _ move: Move,
        on board: GomokuBoard,
        for player: Stone,
        includesDoubleWinPressure: Bool = false,
        deadline: Date? = nil
    ) -> Int {
        var score = linePotential(at: move, on: board, for: player)
        score += linePotential(at: move, on: board, for: player.opponent) * difficulty.defensiveWeight / 100
        if difficulty.prioritizesForcingThreats, includesDoubleWinPressure {
            score += doubleWinPressure(after: move, on: board, for: player, deadline: deadline) * 170_000
            score += doubleWinPressure(after: move, on: board, for: player.opponent, deadline: deadline) * 150_000
        }
        score += centerBias(for: move, boardSize: board.size)
        return score
    }

    private func evaluate(board: GomokuBoard, for player: Stone, deadline: Date? = nil) -> Int {
        guard !isExpired(deadline) else {
            return 0
        }

        var score = scoreSegments(on: board, for: player) -
            scoreSegments(on: board, for: player.opponent) * difficulty.defensiveWeight / 100
        if difficulty.prioritizesForcingThreats {
            score += tacticalPressure(on: board, for: player, deadline: deadline)
            score -= tacticalPressure(on: board, for: player.opponent, deadline: deadline) * difficulty.defensiveWeight / 100
        }
        return score
    }

    private func scoreSegments(on board: GomokuBoard, for stone: Stone) -> Int {
        var total = 0

        for move in board.occupiedMoves where board[move] == stone {
            for direction in GomokuBoard.directions {
                let previous = Move(row: move.row - direction.row, column: move.column - direction.column)
                if board.contains(previous), board[previous] == stone {
                    continue
                }

                var length = 0
                var cursor = move
                while board.contains(cursor), board[cursor] == stone {
                    length += 1
                    cursor = Move(row: cursor.row + direction.row, column: cursor.column + direction.column)
                }

                var openEnds = 0
                if board.contains(previous), board[previous] == nil {
                    openEnds += 1
                }
                if board.contains(cursor), board[cursor] == nil {
                    openEnds += 1
                }

                total += patternScore(length: length, openEnds: openEnds)
            }
        }

        return total
    }

    private func doubleWinPressure(after move: Move, on board: GomokuBoard, for stone: Stone, deadline: Date? = nil) -> Int {
        guard let next = try? board.placing(stone, at: move) else { return 0 }
        let winningReplies = immediateWinningMoves(on: next, for: stone, deadline: deadline).count
        return max(0, winningReplies - 1)
    }

    private func tacticalPressure(on board: GomokuBoard, for stone: Stone, deadline: Date? = nil) -> Int {
        let winningMoves = immediateWinningMoves(on: board, for: stone, deadline: deadline).count
        if winningMoves >= 2 {
            return 1_700_000 + winningMoves * 120_000
        }
        if winningMoves == 1 {
            return 360_000
        }
        return 0
    }

    private func threatProfile(at move: Move, on board: GomokuBoard, for stone: Stone) -> ThreatProfile {
        var wins = 0
        var openFours = 0
        var closedFours = 0
        var openThrees = 0

        for direction in GomokuBoard.directions {
            let forward = countStones(from: move, direction: direction, on: board, for: stone)
            let backward = countStones(
                from: move,
                direction: (row: -direction.row, column: -direction.column),
                on: board,
                for: stone
            )
            let length = 1 + forward.count + backward.count
            let openEnds = (forward.open ? 1 : 0) + (backward.open ? 1 : 0)

            if length >= 5 {
                wins += 1
            } else if length == 4, openEnds == 2 {
                openFours += 1
            } else if length == 4, openEnds == 1 {
                closedFours += 1
            } else if length == 3, openEnds == 2 {
                openThrees += 1
            }
        }

        return ThreatProfile(
            wins: wins,
            openFours: openFours,
            closedFours: closedFours,
            openThrees: openThrees
        )
    }

    private func linePotential(at move: Move, on board: GomokuBoard, for stone: Stone) -> Int {
        var total = 0
        var openThrees = 0
        var fours = 0

        for direction in GomokuBoard.directions {
            let forward = countStones(from: move, direction: direction, on: board, for: stone)
            let backward = countStones(
                from: move,
                direction: (row: -direction.row, column: -direction.column),
                on: board,
                for: stone
            )
            let length = 1 + forward.count + backward.count
            let openEnds = (forward.open ? 1 : 0) + (backward.open ? 1 : 0)
            let score = patternScore(length: length, openEnds: openEnds)

            if length >= 4, openEnds > 0 {
                fours += 1
            }
            if length == 3, openEnds == 2 {
                openThrees += 1
            }

            total += score
        }

        if fours >= 2 {
            total += 650_000
        }
        if openThrees >= 2 {
            total += 90_000
        }

        return total
    }

    private func countStones(
        from move: Move,
        direction: (row: Int, column: Int),
        on board: GomokuBoard,
        for stone: Stone
    ) -> (count: Int, open: Bool) {
        var count = 0
        var cursor = Move(row: move.row + direction.row, column: move.column + direction.column)

        while board.contains(cursor), board[cursor] == stone {
            count += 1
            cursor = Move(row: cursor.row + direction.row, column: cursor.column + direction.column)
        }

        return (count, board.contains(cursor) && board[cursor] == nil)
    }

    private func patternScore(length: Int, openEnds: Int) -> Int {
        if length >= 5 {
            return 1_000_000
        }

        switch (length, openEnds) {
        case (4, 2):
            return 220_000
        case (4, 1):
            return 55_000
        case (3, 2):
            return 12_000
        case (3, 1):
            return 1_400
        case (2, 2):
            return 650
        case (2, 1):
            return 90
        case (1, 2):
            return 12
        default:
            return 1
        }
    }

    private func centerBias(for move: Move, boardSize: Int) -> Int {
        let center = Double(boardSize - 1) / 2.0
        let distance = abs(Double(move.row) - center) + abs(Double(move.column) - center)
        return max(0, 30 - Int(distance * 3.0))
    }

    private func isExpired(_ deadline: Date?) -> Bool {
        guard let deadline else { return false }
        return Date() >= deadline
    }
}

private struct ThreatProfile: Sendable {
    let wins: Int
    let openFours: Int
    let closedFours: Int
    let openThrees: Int
    let winningReplies: Int

    init(wins: Int, openFours: Int, closedFours: Int, openThrees: Int, winningReplies: Int = 0) {
        self.wins = wins
        self.openFours = openFours
        self.closedFours = closedFours
        self.openThrees = openThrees
        self.winningReplies = winningReplies
    }

    var priority: Int {
        if wins > 0 {
            return 1_000_000 + wins
        }
        if winningReplies >= 2 {
            return 930_000 + winningReplies * 10
        }
        if openFours > 0 {
            return 820_000 + openFours * 10 + closedFours
        }
        if winningReplies == 1 {
            return 700_000
        }
        if closedFours >= 2 {
            return 620_000 + closedFours * 10
        }
        if closedFours >= 1, openThrees >= 1 {
            return 430_000 + closedFours * 10 + openThrees
        }
        if openThrees >= 2 {
            return 260_000 + openThrees * 10
        }
        return 0
    }

    func promoted(by winningReplies: Int) -> ThreatProfile {
        ThreatProfile(
            wins: wins,
            openFours: openFours,
            closedFours: closedFours,
            openThrees: openThrees,
            winningReplies: max(self.winningReplies, winningReplies)
        )
    }
}

private struct ThreatCandidate: Sendable {
    let move: Move
    let profile: ThreatProfile
    let score: Int
}
