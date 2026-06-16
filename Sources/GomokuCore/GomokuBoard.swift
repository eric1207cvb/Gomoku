import Foundation

public enum GomokuBoardError: Error, Equatable {
    case outOfBounds
    case occupied
}

public struct GomokuBoard: Equatable, Sendable {
    public static let standardSize = 15
    public static let standardWinLength = 5

    public let size: Int
    public let winLength: Int
    private var cells: [Stone?]

    public init(size: Int = GomokuBoard.standardSize, winLength: Int = GomokuBoard.standardWinLength) {
        precondition(size >= winLength)
        self.size = size
        self.winLength = winLength
        self.cells = Array(repeating: nil, count: size * size)
    }

    public subscript(_ move: Move) -> Stone? {
        guard contains(move) else { return nil }
        return cells[index(for: move)]
    }

    public var movesPlayed: Int {
        cells.reduce(0) { total, stone in
            total + (stone == nil ? 0 : 1)
        }
    }

    public var isEmpty: Bool {
        movesPlayed == 0
    }

    public var emptyMoves: [Move] {
        var moves: [Move] = []
        moves.reserveCapacity(size * size - movesPlayed)

        for row in 0..<size {
            for column in 0..<size {
                let move = Move(row: row, column: column)
                if self[move] == nil {
                    moves.append(move)
                }
            }
        }

        return moves
    }

    public var occupiedMoves: [Move] {
        var moves: [Move] = []
        moves.reserveCapacity(movesPlayed)

        for row in 0..<size {
            for column in 0..<size {
                let move = Move(row: row, column: column)
                if self[move] != nil {
                    moves.append(move)
                }
            }
        }

        return moves
    }

    public func contains(_ move: Move) -> Bool {
        move.row >= 0 && move.row < size && move.column >= 0 && move.column < size
    }

    public func isLegalMove(_ move: Move) -> Bool {
        contains(move) && self[move] == nil
    }

    public mutating func place(_ stone: Stone, at move: Move) throws {
        guard contains(move) else {
            throw GomokuBoardError.outOfBounds
        }
        guard self[move] == nil else {
            throw GomokuBoardError.occupied
        }

        cells[index(for: move)] = stone
    }

    public func placing(_ stone: Stone, at move: Move) throws -> GomokuBoard {
        var copy = self
        try copy.place(stone, at: move)
        return copy
    }

    public func outcome(lastMove: Move? = nil) -> GameOutcome {
        if let lastMove, let line = winningLine(from: lastMove), let winner = self[lastMove] {
            return .win(winner: winner, line: line)
        }

        for move in occupiedMoves {
            if let line = winningLine(from: move), let winner = self[move] {
                return .win(winner: winner, line: line)
            }
        }

        return emptyMoves.isEmpty ? .draw : .ongoing
    }

    public func winningLine(from move: Move) -> [Move]? {
        guard let stone = self[move] else { return nil }

        for direction in Self.directions {
            var backward: [Move] = []
            var cursor = Move(row: move.row - direction.row, column: move.column - direction.column)
            while contains(cursor), self[cursor] == stone {
                backward.append(cursor)
                cursor = Move(row: cursor.row - direction.row, column: cursor.column - direction.column)
            }

            var forward: [Move] = []
            cursor = Move(row: move.row + direction.row, column: move.column + direction.column)
            while contains(cursor), self[cursor] == stone {
                forward.append(cursor)
                cursor = Move(row: cursor.row + direction.row, column: cursor.column + direction.column)
            }

            let line = backward.reversed() + [move] + forward
            if line.count >= winLength {
                return Array(line)
            }
        }

        return nil
    }

    public func candidateMoves(radius: Int = 2) -> [Move] {
        if isEmpty {
            let center = size / 2
            return [Move(row: center, column: center)]
        }

        var candidates = Set<Move>()
        for move in occupiedMoves {
            for rowDelta in -radius...radius {
                for columnDelta in -radius...radius {
                    guard rowDelta != 0 || columnDelta != 0 else { continue }
                    let candidate = Move(row: move.row + rowDelta, column: move.column + columnDelta)
                    if isLegalMove(candidate) {
                        candidates.insert(candidate)
                    }
                }
            }
        }

        let center = Double(size - 1) / 2.0
        return candidates.sorted { lhs, rhs in
            let lhsDistance = pow(Double(lhs.row) - center, 2) + pow(Double(lhs.column) - center, 2)
            let rhsDistance = pow(Double(rhs.row) - center, 2) + pow(Double(rhs.column) - center, 2)
            if lhsDistance == rhsDistance {
                return lhs < rhs
            }
            return lhsDistance < rhsDistance
        }
    }

    public func boardSignature() -> Int {
        var hash = Hasher()
        hash.combine(size)
        hash.combine(winLength)
        for index in cells.indices {
            if let stone = cells[index] {
                hash.combine(index)
                hash.combine(stone)
            }
        }
        return hash.finalize()
    }

    private func index(for move: Move) -> Int {
        move.row * size + move.column
    }

    public static let directions: [(row: Int, column: Int)] = [
        (0, 1),
        (1, 0),
        (1, 1),
        (1, -1)
    ]
}
