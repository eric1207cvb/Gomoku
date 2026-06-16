import Foundation

public enum Stone: String, CaseIterable, Codable, Sendable {
    case black
    case white

    public var opponent: Stone {
        self == .black ? .white : .black
    }

    public var displayName: String {
        switch self {
        case .black:
            "黑棋"
        case .white:
            "白棋"
        }
    }
}
