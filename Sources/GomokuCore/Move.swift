import Foundation

public struct Move: Hashable, Codable, Sendable, Identifiable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    public var id: String {
        "\(row)-\(column)"
    }
}

extension Move: Comparable {
    public static func < (lhs: Move, rhs: Move) -> Bool {
        if lhs.row == rhs.row {
            lhs.column < rhs.column
        } else {
            lhs.row < rhs.row
        }
    }
}
