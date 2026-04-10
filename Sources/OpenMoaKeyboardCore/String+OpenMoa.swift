import Foundation

public extension String {
    func droppingLastCharacters(_ count: Int) -> String {
        guard count > 0 else {
            return self
        }
        return String(dropLast(Swift.min(count, self.count)))
    }
}
