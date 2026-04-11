import CoreGraphics
import Foundation

enum KeyboardPreferences {
    enum Key {
        static let portraitKeyboardHeight = "portraitKeyboardHeight"
        static let landscapeKeyboardWidth = "landscapeKeyboardWidth"
        static let landscapeKeyboardHeight = "landscapeKeyboardHeight"
    }

    enum DefaultValue {
        static let portraitKeyboardHeight: CGFloat = 272
        static let landscapeKeyboardWidth: CGFloat = 372
        static let landscapeKeyboardHeight: CGFloat = 202.5
    }

    private enum RangeLimit {
        static let portraitKeyboardHeight: ClosedRange<CGFloat> = 180...420
        static let landscapeKeyboardWidth: ClosedRange<CGFloat> = 220...520
        static let landscapeKeyboardHeight: ClosedRange<CGFloat> = 140...320
    }

    static let appGroupIdentifier = "group.pe.aioo.openmoa.ios.shared"
    static let sharedDefaults: UserDefaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard

    struct LayoutValues {
        let portraitKeyboardHeight: CGFloat
        let landscapeKeyboardWidth: CGFloat
        let landscapeKeyboardHeight: CGFloat
    }

    static var layoutValues: LayoutValues {
        LayoutValues(
            portraitKeyboardHeight: resolvedCGFloat(
                forKey: Key.portraitKeyboardHeight,
                defaultValue: DefaultValue.portraitKeyboardHeight,
                range: RangeLimit.portraitKeyboardHeight
            ),
            landscapeKeyboardWidth: resolvedCGFloat(
                forKey: Key.landscapeKeyboardWidth,
                defaultValue: DefaultValue.landscapeKeyboardWidth,
                range: RangeLimit.landscapeKeyboardWidth
            ),
            landscapeKeyboardHeight: resolvedCGFloat(
                forKey: Key.landscapeKeyboardHeight,
                defaultValue: DefaultValue.landscapeKeyboardHeight,
                range: RangeLimit.landscapeKeyboardHeight
            )
        )
    }

    static func migrateLegacyValuesIfNeeded() {
        guard !(sharedDefaults === UserDefaults.standard) else {
            return
        }

        let legacyDefaults = UserDefaults.standard
        let keys = [
            Key.portraitKeyboardHeight,
            Key.landscapeKeyboardWidth,
            Key.landscapeKeyboardHeight,
        ]

        for key in keys where sharedDefaults.object(forKey: key) == nil {
            if let legacyValue = legacyDefaults.object(forKey: key) {
                sharedDefaults.set(legacyValue, forKey: key)
            }
        }
    }

    private static func resolvedCGFloat(
        forKey key: String,
        defaultValue: CGFloat,
        range: ClosedRange<CGFloat>
    ) -> CGFloat {
        guard let rawValue = sharedDefaults.object(forKey: key) else {
            return defaultValue
        }

        let numericValue: CGFloat?
        if let number = rawValue as? NSNumber {
            numericValue = CGFloat(number.doubleValue)
        } else if let string = rawValue as? String, let value = Double(string) {
            numericValue = CGFloat(value)
        } else {
            numericValue = nil
        }

        return min(max(numericValue ?? defaultValue, range.lowerBound), range.upperBound)
    }
}
