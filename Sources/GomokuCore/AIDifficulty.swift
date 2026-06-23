import Foundation

public enum AIDifficulty: String, CaseIterable, Codable, Sendable, Identifiable {
    case beginner
    case casual
    case tactical
    case master

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .beginner:
            "入門"
        case .casual:
            "普通"
        case .tactical:
            "困難"
        case .master:
            "高手挑戰"
        }
    }

    public var maximumThinkingTime: TimeInterval {
        3.0
    }

    var searchDepth: Int {
        switch self {
        case .beginner:
            0
        case .casual:
            1
        case .tactical:
            2
        case .master:
            4
        }
    }

    var candidateLimit: Int {
        switch self {
        case .beginner:
            8
        case .casual:
            12
        case .tactical:
            16
        case .master:
            30
        }
    }

    var candidateRadius: Int {
        switch self {
        case .beginner, .casual:
            1
        case .tactical, .master:
            2
        }
    }

    var defensiveWeight: Int {
        switch self {
        case .beginner:
            62
        case .casual:
            88
        case .tactical:
            96
        case .master:
            116
        }
    }

    var blocksImmediateWins: Bool {
        self != .beginner
    }

    var mistakeWindow: Int {
        switch self {
        case .beginner:
            5
        case .casual:
            2
        case .tactical, .master:
            1
        }
    }

    var prioritizesForcingThreats: Bool {
        self == .tactical || self == .master
    }
}
