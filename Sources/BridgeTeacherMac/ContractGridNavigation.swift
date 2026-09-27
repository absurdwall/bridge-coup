import BridgeTeacherCore

enum ContractGridNavigation {
    enum Direction {
        case left
        case right
        case up
        case down
    }

    private static let strains: [ContractStrain] = [.clubs, .diamonds, .hearts, .spades, .noTrump]

    static func destination(from choice: ContractChoice, direction: Direction) -> ContractChoice {
        var level = min(7, max(1, choice.level))
        var column = strains.firstIndex(of: choice.strain) ?? 0

        switch direction {
        case .left:
            column = max(0, column - 1)
        case .right:
            column = min(strains.count - 1, column + 1)
        case .up:
            level = max(1, level - 1)
        case .down:
            level = min(7, level + 1)
        }

        return ContractChoice(level: level, strain: strains[column])
    }
}
