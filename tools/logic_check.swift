import Foundation

enum LogicCheckError: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case let .failed(message):
            "Logic check failed: \(message)"
        }
    }
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw LogicCheckError.failed(message)
    }
}

@main
struct LogicCheck {
    static func main() throws {
        try checkOpeningCandidate()
        try checkHorizontalWin()
        try checkDiagonalWin()
        try checkOccupiedMove()
        try checkAIImmediateWin()
        try checkAIBlock()
        try checkMasterCreatesDoubleOpenThree()
        try checkMasterBlocksDoubleOpenThree()
        try checkMasterCreatesDoubleWinThreat()
        try checkMasterBlocksDoubleWinThreat()
        print("Logic checks passed")
    }

    private static func checkOpeningCandidate() throws {
        let board = GomokuBoard()
        try check(board.movesPlayed == 0, "board should start empty")
        try check(board.candidateMoves() == [Move(row: 7, column: 7)], "first candidate should be center")
        try check(board.outcome() == .ongoing, "new board should be ongoing")
    }

    private static func checkHorizontalWin() throws {
        var board = GomokuBoard()
        var lastMove = Move(row: 7, column: 3)

        for column in 3...7 {
            lastMove = Move(row: 7, column: column)
            try board.place(.black, at: lastMove)
        }

        guard case let .win(winner, line) = board.outcome(lastMove: lastMove) else {
            throw LogicCheckError.failed("expected horizontal win")
        }

        try check(winner == .black, "winner should be black")
        try check(line.count == 5, "horizontal line should contain five moves")
    }

    private static func checkDiagonalWin() throws {
        var board = GomokuBoard()
        var lastMove = Move(row: 2, column: 2)

        for offset in 0..<5 {
            lastMove = Move(row: 2 + offset, column: 2 + offset)
            try board.place(.white, at: lastMove)
        }

        guard case let .win(winner, line) = board.outcome(lastMove: lastMove) else {
            throw LogicCheckError.failed("expected diagonal win")
        }

        try check(winner == .white, "winner should be white")
        try check(line == [
            Move(row: 2, column: 2),
            Move(row: 3, column: 3),
            Move(row: 4, column: 4),
            Move(row: 5, column: 5),
            Move(row: 6, column: 6)
        ], "diagonal line should be ordered")
    }

    private static func checkOccupiedMove() throws {
        var board = GomokuBoard()
        let move = Move(row: 7, column: 7)
        try board.place(.black, at: move)

        do {
            try board.place(.white, at: move)
            throw LogicCheckError.failed("occupied move should throw")
        } catch GomokuBoardError.occupied {
            return
        }
    }

    private static func checkAIImmediateWin() throws {
        var board = GomokuBoard()
        for column in 4...7 {
            try board.place(.white, at: Move(row: 7, column: column))
        }

        let move = LocalGomokuAI(difficulty: .tactical).bestMove(on: board, for: .white)
        try check(move == Move(row: 7, column: 3) || move == Move(row: 7, column: 8), "AI should finish open four")
    }

    private static func checkAIBlock() throws {
        var board = GomokuBoard()
        for column in 4...7 {
            try board.place(.black, at: Move(row: 7, column: column))
        }

        let move = LocalGomokuAI(difficulty: .tactical).bestMove(on: board, for: .white)
        try check(move == Move(row: 7, column: 3) || move == Move(row: 7, column: 8), "AI should block open four")
    }

    private static func checkMasterCreatesDoubleOpenThree() throws {
        var board = GomokuBoard()
        try board.place(.white, at: Move(row: 7, column: 6))
        try board.place(.white, at: Move(row: 7, column: 8))
        try board.place(.white, at: Move(row: 6, column: 7))
        try board.place(.white, at: Move(row: 8, column: 7))

        let move = LocalGomokuAI(difficulty: .master).bestMove(on: board, for: .white)
        try check(move == Move(row: 7, column: 7), "master should create a double open three")
    }

    private static func checkMasterBlocksDoubleOpenThree() throws {
        var board = GomokuBoard()
        try board.place(.black, at: Move(row: 7, column: 6))
        try board.place(.black, at: Move(row: 7, column: 8))
        try board.place(.black, at: Move(row: 6, column: 7))
        try board.place(.black, at: Move(row: 8, column: 7))

        let move = LocalGomokuAI(difficulty: .master).bestMove(on: board, for: .white)
        try check(move == Move(row: 7, column: 7), "master should block an opponent double open three")
    }

    private static func checkMasterCreatesDoubleWinThreat() throws {
        var board = GomokuBoard()
        try board.place(.white, at: Move(row: 7, column: 5))
        try board.place(.white, at: Move(row: 7, column: 6))
        try board.place(.white, at: Move(row: 7, column: 8))
        try board.place(.white, at: Move(row: 5, column: 7))
        try board.place(.white, at: Move(row: 6, column: 7))
        try board.place(.white, at: Move(row: 8, column: 7))

        let move = LocalGomokuAI(difficulty: .master).bestMove(on: board, for: .white)
        try check(move == Move(row: 7, column: 7), "master should create a double win threat")
    }

    private static func checkMasterBlocksDoubleWinThreat() throws {
        var board = GomokuBoard()
        try board.place(.black, at: Move(row: 7, column: 5))
        try board.place(.black, at: Move(row: 7, column: 6))
        try board.place(.black, at: Move(row: 7, column: 8))
        try board.place(.black, at: Move(row: 5, column: 7))
        try board.place(.black, at: Move(row: 6, column: 7))
        try board.place(.black, at: Move(row: 8, column: 7))

        let move = LocalGomokuAI(difficulty: .master).bestMove(on: board, for: .white)
        try check(move == Move(row: 7, column: 7), "master should block an opponent double win threat")
    }
}
