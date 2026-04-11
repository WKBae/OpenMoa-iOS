import CoreGraphics
import Foundation

enum KeyboardPreferences {
    enum Key {
        static let portraitKeyboardHeight = "portraitKeyboardHeight"
        static let landscapeKeyboardWidth = "landscapeKeyboardWidth"
        static let landscapeKeyboardHeight = "landscapeKeyboardHeight"
        static let deleteStartsWithVowel = "deleteStartsWithVowel"
        static let koreanLeadingKeyTop = "koreanLeadingKeyTop"
        static let koreanLeadingKeyUpperMiddle = "koreanLeadingKeyUpperMiddle"
        static let koreanLeadingKeyLowerMiddle = "koreanLeadingKeyLowerMiddle"
        static let koreanLeadingKeyBottom = "koreanLeadingKeyBottom"
        static let spaceLeadingKey = "spaceLeadingKey"
    }

    enum DefaultValue {
        static let portraitKeyboardHeight: CGFloat = 272
        static let landscapeKeyboardWidth: CGFloat = 372
        static let landscapeKeyboardHeight: CGFloat = 202.5
        static let deleteStartsWithVowel = true
        static let koreanLeadingKeyTop = "~"
        static let koreanLeadingKeyUpperMiddle = "^"
        static let koreanLeadingKeyLowerMiddle = ";"
        static let koreanLeadingKeyBottom = "*"
        static let spaceLeadingKey = ","
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

    struct KoreanLeadingKeyValues {
        let top: String
        let upperMiddle: String
        let lowerMiddle: String
        let bottom: String
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

    static var koreanLeadingKeyValues: KoreanLeadingKeyValues {
        KoreanLeadingKeyValues(
            top: resolvedString(
                forKey: Key.koreanLeadingKeyTop,
                defaultValue: DefaultValue.koreanLeadingKeyTop
            ),
            upperMiddle: resolvedString(
                forKey: Key.koreanLeadingKeyUpperMiddle,
                defaultValue: DefaultValue.koreanLeadingKeyUpperMiddle
            ),
            lowerMiddle: resolvedString(
                forKey: Key.koreanLeadingKeyLowerMiddle,
                defaultValue: DefaultValue.koreanLeadingKeyLowerMiddle
            ),
            bottom: resolvedString(
                forKey: Key.koreanLeadingKeyBottom,
                defaultValue: DefaultValue.koreanLeadingKeyBottom
            )
        )
    }

    static var spaceLeadingKeyValue: String {
        resolvedString(
            forKey: Key.spaceLeadingKey,
            defaultValue: DefaultValue.spaceLeadingKey
        )
    }

    static var deleteStartsWithVowel: Bool {
        resolvedBool(
            forKey: Key.deleteStartsWithVowel,
            defaultValue: DefaultValue.deleteStartsWithVowel
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
            Key.spaceLeadingKey,
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

    private static func resolvedString(forKey key: String, defaultValue: String) -> String {
        let rawValue = sharedDefaults.string(forKey: key)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let rawValue, !rawValue.isEmpty else {
            return defaultValue
        }

        return String(rawValue.prefix(3))
    }

    private static func resolvedBool(forKey key: String, defaultValue: Bool) -> Bool {
        guard let rawValue = sharedDefaults.object(forKey: key) else {
            return defaultValue
        }

        if let number = rawValue as? NSNumber {
            return number.boolValue
        }

        if let string = rawValue as? String {
            switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "1", "true", "yes":
                return true
            case "0", "false", "no":
                return false
            default:
                break
            }
        }

        return defaultValue
    }
}
