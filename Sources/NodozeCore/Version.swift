import Foundation

public struct SemanticVersion: Comparable, Sendable {
    public let components: [Int]

    public init(_ rawValue: String) {
        components = rawValue
            .split(separator: ".")
            .map { Int($0.filter(\.isNumber)) ?? 0 }
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)

        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0

            if left != right {
                return left < right
            }
        }

        return false
    }

    public static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}
