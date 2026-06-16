import Foundation
import SwiftUI

enum GameMode: String, CaseIterable, Identifiable {
    case versusAI
    case localTwoPlayer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .versusAI:
            "AI 對戰"
        case .localTwoPlayer:
            "雙人"
        }
    }
}

struct MoveRecord: Identifiable, Equatable {
    let id = UUID()
    let number: Int
    let stone: Stone
    let move: Move

    var notation: String {
        let letterIndex = min(max(move.column, 0), 25)
        let scalar = UnicodeScalar(65 + letterIndex) ?? "A"
        return "\(Character(scalar))\(move.row + 1)"
    }
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var board = GomokuBoard()
    @Published private(set) var currentTurn: Stone = .black
    @Published private(set) var outcome: GameOutcome = .ongoing
    @Published private(set) var lastMove: Move?
    @Published private(set) var winningLine: [Move] = []
    @Published private(set) var moveHistory: [MoveRecord] = []
    @Published private(set) var isAIThinking = false
    @Published var difficulty: AIDifficulty = .casual
    @Published var mode: GameMode = .versusAI

    private var aiTask: Task<Void, Never>?
    private var gameRevision = 0
    private let aiStone: Stone = .white

    var statusTitle: String {
        switch outcome {
        case .ongoing where isAIThinking:
            "AI 思考中"
        case .ongoing:
            "\(currentTurn.displayName)回合"
        case .draw:
            "平手"
        case let .win(winner, _):
            mode == .versusAI && winner == aiStone ? "差一點，再挑戰" : "\(winner.displayName)獲勝"
        }
    }

    var moveCountText: String {
        "\(board.movesPlayed) / \(board.size * board.size)"
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

    func startNewGame() {
        aiTask?.cancel()
        aiTask = nil
        board = GomokuBoard()
        currentTurn = .black
        outcome = .ongoing
        lastMove = nil
        winningLine = []
        moveHistory = []
        isAIThinking = false
        gameRevision += 1
    }

    @discardableResult
    func handleTap(on move: Move) -> Bool {
        guard canTapBoard, board.isLegalMove(move) else { return false }
        return place(currentTurn, at: move)
    }

    @discardableResult
    private func place(_ stone: Stone, at move: Move) -> Bool {
        do {
            try board.place(stone, at: move)
        } catch {
            return false
        }

        lastMove = move
        moveHistory.append(MoveRecord(number: moveHistory.count + 1, stone: stone, move: move))

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

        isAIThinking = true
        aiTask?.cancel()
        aiTask = Task { [weak self] in
            let move = await Task.detached(priority: .userInitiated) {
                LocalGomokuAI(difficulty: currentDifficulty).bestMove(on: snapshot, for: .white)
            }.value

            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, self.gameRevision == revision else { return }
                self.isAIThinking = false
                if let move, self.board.isLegalMove(move) {
                    self.place(.white, at: move)
                }
            }
        }
    }
}
