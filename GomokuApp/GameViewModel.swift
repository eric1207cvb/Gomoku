import Foundation
import SwiftUI

enum GameMode: String, CaseIterable, Identifiable {
    case versusAI
    case localTwoPlayer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .versusAI:
            "單人"
        case .localTwoPlayer:
            "雙人"
        }
    }
}

enum StartingPlayer: String, CaseIterable, Identifiable {
    case human
    case ai

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .human:
            "玩家先手"
        case .ai:
            "AI先手"
        }
    }
}

struct BeginnerMoveHint: Identifiable, Equatable {
    let move: Move
    let title: String
    let detail: String

    var id: String { move.id }
}

private struct PlayedMove {
    let stone: Stone
    let move: Move
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var board = GomokuBoard()
    @Published private(set) var currentTurn: Stone = .black
    @Published private(set) var outcome: GameOutcome = .ongoing
    @Published private(set) var lastMove: Move?
    @Published private(set) var winningLine: [Move] = []
    @Published private(set) var lastAIMove: Move?
    @Published private(set) var aiHighlightedMove: Move?
    @Published private(set) var isAIThinking = false
    @Published private(set) var gameID = 0
    @Published private(set) var undoUsedThisGame = false
    @Published var difficulty: AIDifficulty = .casual
    @Published var mode: GameMode = .versusAI
    @Published private(set) var startingPlayer: StartingPlayer = .human
    @Published var isBeginnerMoveHintEnabled = true
    @Published var isTurnHandoffPromptEnabled = true

    private var aiTask: Task<Void, Never>?
    private var aiHighlightTask: Task<Void, Never>?
    private var moveStack: [PlayedMove] = []
    private var gameRevision = 0
    private let minimumAIResponseDuration: TimeInterval = 0.95
    private var aiStone: Stone {
        startingPlayer == .ai ? .black : .white
    }

    var statusTitle: String {
        switch outcome {
        case .ongoing where isAIThinking:
            return "AI 思考中"
        case .ongoing:
            return "\(currentTurn.displayName)回合"
        case .draw:
            return "平手"
        case let .win(winner, _):
            return mode == .versusAI && winner == aiStone ? aiLossTitle : "\(winner.displayName)獲勝"
        }
    }

    var moveCountText: String {
        "\(board.movesPlayed) / \(board.size * board.size)"
    }

    var boardGuideMoves: [Move] {
        return beginnerMoveHints.map(\.move)
    }

    var beginnerCoachTitle: String? {
        guard difficulty == .beginner else { return nil }
        if case .win = outcome {
            return "完成一局"
        }
        if isAIThinking || (mode == .versusAI && currentTurn == aiStone) {
            return "換 AI 想一下"
        }
        if board.isEmpty {
            return "先從中間開始"
        }
        if !immediateWinningMoves(for: currentTurn).isEmpty {
            return "快連成五了"
        }
        if !immediateWinningMoves(for: currentTurn.opponent).isEmpty {
            return "先擋住對方"
        }
        return "輪到你囉"
    }

    var beginnerCoachMessage: String? {
        guard difficulty == .beginner else { return nil }
        if case .win = outcome {
            return "五顆連在一起就會贏。"
        }
        if isAIThinking || (mode == .versusAI && currentTurn == aiStone) {
            return "等 AI 下完，再輪到你。"
        }
        if board.isEmpty {
            return "第一步下在中間附近，比較容易連線。"
        }
        if !immediateWinningMoves(for: currentTurn).isEmpty {
            return "找亮亮的位置，把五顆接起來。"
        }
        if !immediateWinningMoves(for: currentTurn.opponent).isEmpty {
            return "對方快連成五顆，先放在亮亮的位置。"
        }
        return "把自己的棋連成 5 顆就獲勝。"
    }

    var canUndoMove: Bool {
        guard difficulty == .beginner || difficulty == .casual else { return false }
        guard !undoUsedThisGame else { return false }
        guard !moveStack.isEmpty else { return false }
        if mode == .versusAI {
            return moveStack.contains { $0.stone != aiStone }
        }
        return true
    }

    var undoStatusText: String {
        if difficulty != .beginner && difficulty != .casual {
            return "困難關閉"
        }
        return undoUsedThisGame ? "已使用" : "可用一次"
    }

    var beginnerMoveHints: [BeginnerMoveHint] {
        guard difficulty == .beginner, isBeginnerMoveHintEnabled, canTapBoard else { return [] }

        if board.isEmpty {
            return openingHints(limit: 3)
        }

        let winningMoves = immediateWinningMoves(for: currentTurn)
        if !winningMoves.isEmpty {
            return winningMoves.prefix(3).map {
                BeginnerMoveHint(move: $0, title: "連五機會", detail: "先看這裡")
            }
        }

        let blockingMoves = immediateWinningMoves(for: currentTurn.opponent)
        if !blockingMoves.isEmpty {
            return blockingMoves.prefix(3).map {
                BeginnerMoveHint(move: $0, title: "守住這裡", detail: "擋住對方")
            }
        }

        return board.candidateMoves(radius: 2)
            .map { (move: $0, score: beginnerHintScore(for: $0)) }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.move < rhs.move
                }
                return lhs.score > rhs.score
            }
            .prefix(3)
            .enumerated()
            .map { index, candidate in
                BeginnerMoveHint(
                    move: candidate.move,
                    title: index == 0 ? "推薦落點" : "也可以走",
                    detail: index == 0 ? "靠近棋群" : "練習觀察"
                )
            }
    }

    var canTapBoard: Bool {
        guard case .ongoing = outcome else { return false }
        guard !isAIThinking else { return false }
        return !(mode == .versusAI && currentTurn == aiStone)
    }

    func isAIVictory(_ outcome: GameOutcome) -> Bool {
        guard case let .win(winner, _) = outcome else {
            return false
        }

        return mode == .versusAI && winner == aiStone
    }

    func selectDifficulty(_ newDifficulty: AIDifficulty) {
        guard difficulty != newDifficulty else { return }
        difficulty = newDifficulty
        startNewGame()
    }

    func selectMode(_ newMode: GameMode) {
        guard mode != newMode else { return }
        mode = newMode
        startNewGame()
    }

    func toggleStartingPlayer() {
        startingPlayer = startingPlayer == .human ? .ai : .human
        startNewGame()
    }

    func startNewGame() {
        aiTask?.cancel()
        aiTask = nil
        aiHighlightTask?.cancel()
        aiHighlightTask = nil
        board = GomokuBoard()
        currentTurn = .black
        outcome = .ongoing
        lastMove = nil
        winningLine = []
        lastAIMove = nil
        aiHighlightedMove = nil
        isAIThinking = false
        moveStack = []
        undoUsedThisGame = false
        gameRevision += 1
        gameID += 1
        scheduleAIIfNeeded()
    }

    @discardableResult
    func handleTap(on move: Move) -> Bool {
        guard canTapBoard, board.isLegalMove(move) else { return false }
        return place(currentTurn, at: move)
    }

    func toggleTurnHandoffPrompt() {
        isTurnHandoffPromptEnabled.toggle()
    }

    func toggleBeginnerMoveHints() {
        isBeginnerMoveHintEnabled.toggle()
    }

    @discardableResult
    func undoMove() -> Bool {
        guard canUndoMove else { return false }

        aiTask?.cancel()
        aiTask = nil
        aiHighlightTask?.cancel()
        aiHighlightTask = nil

        let removeCount: Int
        if mode == .versusAI {
            if isAIThinking {
                removeCount = 1
            } else if let last = moveStack.last, last.stone == aiStone {
                removeCount = min(2, moveStack.count)
            } else {
                removeCount = 1
            }
        } else {
            removeCount = 1
        }

        guard removeCount > 0, moveStack.count >= removeCount else { return false }
        let removedMoves = Array(moveStack.suffix(removeCount))
        moveStack.removeLast(removeCount)
        rebuildBoardFromMoveStack()

        currentTurn = removedMoves.first?.stone ?? .black
        outcome = board.outcome(lastMove: lastMove)
        winningLine = outcome.winningLine
        isAIThinking = false
        aiHighlightedMove = nil
        undoUsedThisGame = true
        gameRevision += 1
        gameID += 1
        return true
    }

    @discardableResult
    private func place(_ stone: Stone, at move: Move) -> Bool {
        do {
            try board.place(stone, at: move)
        } catch {
            return false
        }

        lastMove = move
        moveStack.append(PlayedMove(stone: stone, move: move))
        if mode == .versusAI, stone == aiStone {
            lastAIMove = move
            showAIHighlight(at: move)
        }

        outcome = board.outcome(lastMove: move)
        winningLine = outcome.winningLine

        guard case .ongoing = outcome else {
            isAIThinking = false
            return true
        }

        currentTurn = stone.opponent
        scheduleAIIfNeeded()
        return true
    }

    private func scheduleAIIfNeeded() {
        guard mode == .versusAI, currentTurn == aiStone else { return }

        let snapshot = board
        let currentDifficulty = difficulty
        let revision = gameRevision
        let maximumThinkingTime = currentDifficulty.maximumThinkingTime
        let activeAIStone = aiStone
        let aiTurnStartedAt = Date()
        let minimumResponseDuration = minimumAIResponseDuration

        isAIThinking = true
        aiTask?.cancel()
        aiTask = Task { [weak self] in
            let move = await Task.detached(priority: .userInitiated) {
                LocalGomokuAI(difficulty: currentDifficulty).bestMove(
                    on: snapshot,
                    for: activeAIStone,
                    maximumThinkingTime: maximumThinkingTime
                )
            }.value

            guard !Task.isCancelled else { return }

            let elapsed = Date().timeIntervalSince(aiTurnStartedAt)
            let remainingDelay = minimumResponseDuration - elapsed
            if remainingDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remainingDelay * 1_000_000_000))
                guard !Task.isCancelled else { return }
            }

            await MainActor.run {
                guard let self, self.gameRevision == revision else { return }
                self.isAIThinking = false
                if let move, self.board.isLegalMove(move) {
                    self.place(activeAIStone, at: move)
                }
            }
        }
    }
}

private extension GameViewModel {
    func rebuildBoardFromMoveStack() {
        var nextBoard = GomokuBoard()
        for playedMove in moveStack {
            try? nextBoard.place(playedMove.stone, at: playedMove.move)
        }

        board = nextBoard
        lastMove = moveStack.last?.move
        if mode == .versusAI {
            lastAIMove = moveStack.last(where: { $0.stone == aiStone })?.move
        } else {
            lastAIMove = nil
        }
    }

    func showAIHighlight(at move: Move) {
        aiHighlightTask?.cancel()
        aiHighlightedMove = move
        aiHighlightTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, self.aiHighlightedMove == move else { return }
                self.aiHighlightedMove = nil
            }
        }
    }

    var aiLossTitle: String {
        difficulty == .master ? "爸爸媽媽加油" : "再試一次吧"
    }

    func openingHints(limit: Int) -> [BeginnerMoveHint] {
        let center = board.size / 2
        let openingMoves = [
            Move(row: center, column: center),
            Move(row: center - 1, column: center),
            Move(row: center, column: center - 1),
            Move(row: center + 1, column: center),
            Move(row: center, column: center + 1)
        ].filter(board.isLegalMove)

        return openingMoves.prefix(limit).enumerated().map { index, move in
            BeginnerMoveHint(
                move: move,
                title: index == 0 ? "從中心開始" : "中心附近",
                detail: index == 0 ? "最容易展開" : "也很好走"
            )
        }
    }

    func immediateWinningMoves(for stone: Stone) -> [Move] {
        board.candidateMoves(radius: 2).filter { move in
            guard let next = try? board.placing(stone, at: move) else { return false }
            if case .win = next.outcome(lastMove: move) {
                return true
            }
            return false
        }
    }

    func beginnerHintScore(for move: Move) -> Int {
        let attack = linePotentialScore(at: move, for: currentTurn)
        let defense = linePotentialScore(at: move, for: currentTurn.opponent)
        let nearby = nearbyStoneCount(around: move)
        let center = Double(board.size - 1) / 2.0
        let centerDistance = abs(Double(move.row) - center) + abs(Double(move.column) - center)
        let centerBonus = max(0, 24 - Int(centerDistance * 2))

        return attack * 10 + defense * 8 + nearby * 18 + centerBonus
    }

    func linePotentialScore(at move: Move, for stone: Stone) -> Int {
        var best = 0
        for direction in GomokuBoard.directions {
            let forward = continuousRun(from: move, direction: direction, for: stone)
            let backward = continuousRun(
                from: move,
                direction: (row: -direction.row, column: -direction.column),
                for: stone
            )
            let length = 1 + forward.count + backward.count
            let openEnds = (forward.isOpen ? 1 : 0) + (backward.isOpen ? 1 : 0)
            best = max(best, patternScore(length: length, openEnds: openEnds))
        }
        return best
    }

    func continuousRun(
        from move: Move,
        direction: (row: Int, column: Int),
        for stone: Stone
    ) -> (count: Int, isOpen: Bool) {
        var count = 0
        var cursor = Move(row: move.row + direction.row, column: move.column + direction.column)

        while board.contains(cursor), board[cursor] == stone {
            count += 1
            cursor = Move(row: cursor.row + direction.row, column: cursor.column + direction.column)
        }

        return (count, board.contains(cursor) && board[cursor] == nil)
    }

    func patternScore(length: Int, openEnds: Int) -> Int {
        switch (length, openEnds) {
        case (5..., _):
            10_000
        case (4, 2):
            2_400
        case (4, 1):
            1_000
        case (3, 2):
            520
        case (3, 1):
            240
        case (2, 2):
            110
        case (2, 1):
            60
        default:
            20
        }
    }

    func nearbyStoneCount(around move: Move) -> Int {
        var count = 0
        for rowDelta in -1...1 {
            for columnDelta in -1...1 {
                guard rowDelta != 0 || columnDelta != 0 else { continue }
                let neighbor = Move(row: move.row + rowDelta, column: move.column + columnDelta)
                if board.contains(neighbor), board[neighbor] != nil {
                    count += 1
                }
            }
        }
        return count
    }
}

extension Move {
    var boardNotation: String {
        let letterIndex = min(max(column, 0), 25)
        let scalar = UnicodeScalar(65 + letterIndex) ?? "A"
        return "\(Character(scalar))\(row + 1)"
    }
}
