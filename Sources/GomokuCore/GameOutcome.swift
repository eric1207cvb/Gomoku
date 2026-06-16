import Foundation

public enum GameOutcome: Equatable, Sendable {
    case ongoing
    case draw
    case win(winner: Stone, line: [Move])

    public var isFinished: Bool {
        switch self {
        case .ongoing:
            false
        case .draw, .win:
            true
        }
    }

    public var winner: Stone? {
        if case let .win(winner, _) = self {
            winner
        } else {
            nil
        }
    }

    public var winningLine: [Move] {
        if case let .win(_, line) = self {
            line
        } else {
            []
        }
    }
}
