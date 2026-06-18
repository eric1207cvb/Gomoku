import XCTest
@testable import GomokuCore

final class GomokuCoreTests: XCTestCase {
    func testBoardStartsEmptyAndSuggestsCenter() {
        let board = GomokuBoard()

        XCTAssertEqual(board.movesPlayed, 0)
        XCTAssertEqual(board.candidateMoves(), [Move(row: 7, column: 7)])
        XCTAssertEqual(board.outcome(), .ongoing)
    }

    func testDetectsHorizontalWin() throws {
        var board = GomokuBoard()
        var lastMove = Move(row: 7, column: 3)

        for column in 3...7 {
            lastMove = Move(row: 7, column: column)
            try board.place(.black, at: lastMove)
        }

        guard case let .win(winner, line) = board.outcome(lastMove: lastMove) else {
            return XCTFail("Expected a black win")
        }

        XCTAssertEqual(winner, .black)
        XCTAssertEqual(line.count, 5)
    }

    func testDetectsDiagonalWin() throws {
        var board = GomokuBoard()
        var lastMove = Move(row: 2, column: 2)

        for offset in 0..<5 {
            lastMove = Move(row: 2 + offset, column: 2 + offset)
            try board.place(.white, at: lastMove)
        }

        guard case let .win(winner, line) = board.outcome(lastMove: lastMove) else {
            return XCTFail("Expected a white win")
        }

        XCTAssertEqual(winner, .white)
        XCTAssertEqual(line, [
            Move(row: 2, column: 2),
            Move(row: 3, column: 3),
            Move(row: 4, column: 4),
            Move(row: 5, column: 5),
            Move(row: 6, column: 6)
        ])
    }

    func testRejectsOccupiedMoves() throws {
        var board = GomokuBoard()
        let move = Move(row: 7, column: 7)

        try board.place(.black, at: move)

        XCTAssertThrowsError(try board.place(.white, at: move)) { error in
            XCTAssertEqual(error as? GomokuBoardError, .occupied)
        }
    }

    func testAIFindsImmediateWin() throws {
        var board = GomokuBoard()
        for column in 4...7 {
            try board.place(.white, at: Move(row: 7, column: column))
        }

        let ai = LocalGomokuAI(difficulty: .tactical)
        let move = ai.bestMove(on: board, for: .white)

        XCTAssertTrue(move == Move(row: 7, column: 3) || move == Move(row: 7, column: 8))
    }

    func testAIBlocksImmediateWin() throws {
        var board = GomokuBoard()
        for column in 4...7 {
            try board.place(.black, at: Move(row: 7, column: column))
        }

        let ai = LocalGomokuAI(difficulty: .tactical)
        let move = ai.bestMove(on: board, for: .white)

        XCTAssertTrue(move == Move(row: 7, column: 3) || move == Move(row: 7, column: 8))
    }

    func testMasterDifficultyUsesDeepestSearchAndLargestCandidatePool() {
        XCTAssertEqual(AIDifficulty.master.displayName, "家長挑戰")
        XCTAssertEqual(AIDifficulty.master.maximumThinkingTime, 3.0)
        XCTAssertGreaterThan(AIDifficulty.master.searchDepth, AIDifficulty.tactical.searchDepth)
        XCTAssertGreaterThan(AIDifficulty.master.candidateLimit, AIDifficulty.tactical.candidateLimit)
        XCTAssertEqual(AIDifficulty.master.mistakeWindow, 1)
        XCTAssertTrue(AIDifficulty.tactical.prioritizesForcingThreats)
        XCTAssertTrue(AIDifficulty.master.prioritizesForcingThreats)
    }

    func testTacticalCreatesSingleReplyForcingThreatAtBoardEdge() throws {
        var board = GomokuBoard()
        try board.place(.white, at: Move(row: 0, column: 0))
        try board.place(.white, at: Move(row: 0, column: 1))
        try board.place(.white, at: Move(row: 0, column: 2))

        let ai = LocalGomokuAI(difficulty: .tactical)
        let move = ai.bestMove(on: board, for: .white)

        XCTAssertEqual(move, Move(row: 0, column: 3))
    }

    func testTacticalBlocksOpponentSingleReplyForcingThreatAtBoardEdge() throws {
        var board = GomokuBoard()
        try board.place(.black, at: Move(row: 0, column: 0))
        try board.place(.black, at: Move(row: 0, column: 1))
        try board.place(.black, at: Move(row: 0, column: 2))

        let ai = LocalGomokuAI(difficulty: .tactical)
        let move = ai.bestMove(on: board, for: .white)

        XCTAssertEqual(move, Move(row: 0, column: 3))
    }

    func testMasterCreatesDoubleOpenThreeThreat() throws {
        var board = GomokuBoard()
        try board.place(.white, at: Move(row: 7, column: 6))
        try board.place(.white, at: Move(row: 7, column: 8))
        try board.place(.white, at: Move(row: 6, column: 7))
        try board.place(.white, at: Move(row: 8, column: 7))

        let ai = LocalGomokuAI(difficulty: .master)
        let move = ai.bestMove(on: board, for: .white)

        XCTAssertEqual(move, Move(row: 7, column: 7))
    }

    func testMasterBlocksOpponentDoubleOpenThreeThreat() throws {
        var board = GomokuBoard()
        try board.place(.black, at: Move(row: 7, column: 6))
        try board.place(.black, at: Move(row: 7, column: 8))
        try board.place(.black, at: Move(row: 6, column: 7))
        try board.place(.black, at: Move(row: 8, column: 7))

        let ai = LocalGomokuAI(difficulty: .master)
        let move = ai.bestMove(on: board, for: .white)

        XCTAssertEqual(move, Move(row: 7, column: 7))
    }

    func testMasterCreatesDoubleWinThreat() throws {
        var board = GomokuBoard()
        try board.place(.white, at: Move(row: 7, column: 5))
        try board.place(.white, at: Move(row: 7, column: 6))
        try board.place(.white, at: Move(row: 7, column: 8))
        try board.place(.white, at: Move(row: 5, column: 7))
        try board.place(.white, at: Move(row: 6, column: 7))
        try board.place(.white, at: Move(row: 8, column: 7))

        let ai = LocalGomokuAI(difficulty: .master)
        let move = ai.bestMove(on: board, for: .white)

        XCTAssertEqual(move, Move(row: 7, column: 7))
    }

    func testMasterBlocksOpponentDoubleWinThreat() throws {
        var board = GomokuBoard()
        try board.place(.black, at: Move(row: 7, column: 5))
        try board.place(.black, at: Move(row: 7, column: 6))
        try board.place(.black, at: Move(row: 7, column: 8))
        try board.place(.black, at: Move(row: 5, column: 7))
        try board.place(.black, at: Move(row: 6, column: 7))
        try board.place(.black, at: Move(row: 8, column: 7))

        let ai = LocalGomokuAI(difficulty: .master)
        let move = ai.bestMove(on: board, for: .white)

        XCTAssertEqual(move, Move(row: 7, column: 7))
    }
}
