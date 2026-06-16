import Foundation

public struct LocalGomokuAI: Sendable {
    private let difficulty: AIDifficulty

    public init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
    }

    public func bestMove(on board: GomokuBoard, for player: Stone) -> Move? {
        let ordered = orderedCandidates(on: board, for: player, limit: difficulty.candidateLimit)
        guard !ordered.isEmpty else { return nil }

        if let winningMove = immediateWinningMove(on: board, for: player) {
            return winningMove
        }

        if difficulty.blocksImmediateWins,
           let blockingMove = immediateWinningMove(on: board, for: player.opponent) {
            return blockingMove
        }

        if difficulty.searchDepth == 0 {
            return relaxedChoice(from: ordered, board: board)
        }

        var bestMove = ordered[0]
        var bestScore = Int.min / 4
        var alpha = Int.min / 4
        let beta = Int.max / 4

        for move in ordered {
            guard let next = try? board.placing(player, at: move) else { continue }
            let score = minimax(
                board: next,
                depth: difficulty.searchDepth - 1,
                currentPlayer: player.opponent,
                rootPlayer: player,
                alpha: alpha,
                beta: beta
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
        beta: Int
    ) -> Int {
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
            return evaluate(board: board, for: rootPlayer)
        }

        let limit = max(8, difficulty.candidateLimit - (difficulty.searchDepth - depth) * 4)
        let candidates = orderedCandidates(on: board, for: currentPlayer, limit: limit)
        guard !candidates.isEmpty else { return 0 }

        if currentPlayer == rootPlayer {
            var value = Int.min / 4
            var localAlpha = alpha
            for move in candidates {
                guard let next = try? board.placing(currentPlayer, at: move) else { continue }
                value = max(
                    value,
                    minimax(
                        board: next,
                        depth: depth - 1,
                        currentPlayer: currentPlayer.opponent,
                        rootPlayer: rootPlayer,
                        alpha: localAlpha,
                        beta: beta
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
                guard let next = try? board.placing(currentPlayer, at: move) else { continue }
                value = min(
                    value,
                    minimax(
                        board: next,
                        depth: depth - 1,
                        currentPlayer: currentPlayer.opponent,
                        rootPlayer: rootPlayer,
                        alpha: alpha,
                        beta: localBeta
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

    private func orderedCandidates(on board: GomokuBoard, for player: Stone, limit: Int) -> [Move] {
        board.candidateMoves(radius: difficulty.candidateRadius)
            .map { move in
                (move: move, score: moveScore(move, on: board, for: player))
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.move < rhs.move
                }
                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map(\.move)
    }

    private func immediateWinningMove(on board: GomokuBoard, for player: Stone) -> Move? {
        board.candidateMoves(radius: 2)
            .sorted()
            .first { move in
                guard let next = try? board.placing(player, at: move) else { return false }
                if case .win = next.outcome(lastMove: move) {
                    return true
                }
                return false
            }
    }

    private func relaxedChoice(from ordered: [Move], board: GomokuBoard) -> Move {
        let window = max(1, min(difficulty.mistakeWindow, ordered.count))
        let signature = UInt(bitPattern: board.boardSignature())
        return ordered[Int(signature % UInt(window))]
    }

    private func moveScore(_ move: Move, on board: GomokuBoard, for player: Stone) -> Int {
        var score = linePotential(at: move, on: board, for: player)
        score += linePotential(at: move, on: board, for: player.opponent) * difficulty.defensiveWeight / 100
        score += centerBias(for: move, boardSize: board.size)
        return score
    }

    private func evaluate(board: GomokuBoard, for player: Stone) -> Int {
        scoreSegments(on: board, for: player) - scoreSegments(on: board, for: player.opponent)
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
}
