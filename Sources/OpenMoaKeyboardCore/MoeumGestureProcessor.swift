import Foundation

public final class MoeumGestureProcessor {
    private var moeumList: [String] = []

    public init() {}

    public func appendMoeum(_ moeum: String) {
        moeumList.append(moeum)
    }

    public func clear() {
        moeumList.removeAll()
    }

    public func resolveMoeumList() -> String? {
        var moeum: String?
        for nextMoeum in moeumList {
            moeum = switch moeum {
            case "ㅏ":
                switch nextMoeum {
                case "ㅓ", "ㅗ", "ㅜ", "ㅡL", "ㅣL": "ㅐ"
                default: moeum
                }
            case "ㅐ":
                switch nextMoeum {
                case "ㅏ", "ㅡR", "ㅣR": "ㅑ"
                default: moeum
                }
            case "ㅑ":
                switch nextMoeum {
                case "ㅓ", "ㅡL", "ㅣL": "ㅒ"
                default: moeum
                }
            case "ㅓ":
                switch nextMoeum {
                case "ㅏ", "ㅗ", "ㅜ", "ㅡR", "ㅣR": "ㅔ"
                default: moeum
                }
            case "ㅔ":
                switch nextMoeum {
                case "ㅓ", "ㅡL", "ㅣL": "ㅕ"
                default: moeum
                }
            case "ㅕ":
                switch nextMoeum {
                case "ㅏ", "ㅡR", "ㅣR": "ㅖ"
                default: moeum
                }
            case "ㅗ":
                switch nextMoeum {
                case "ㅏ": "ㅘ"
                case "ㅜ", "ㅡL", "ㅡR": "ㅚ"
                default: moeum
                }
            case "ㅘ":
                switch nextMoeum {
                case "ㅓ", "ㅜ", "ㅡL", "ㅡR": "ㅙ"
                case "ㅗ": "ㅛ"
                default: moeum
                }
            case "ㅚ":
                switch nextMoeum {
                case "ㅏ": "ㅘ"
                case "ㅗ", "ㅣL", "ㅣR": "ㅛ"
                case "ㅓ": "ㅕ"
                default: moeum
                }
            case "ㅜ":
                switch nextMoeum {
                case "ㅓ": "ㅝ"
                case "ㅗ", "ㅣL", "ㅣR": "ㅟ"
                default: moeum
                }
            case "ㅝ":
                switch nextMoeum {
                case "ㅏ", "ㅗ", "ㅡR", "ㅣR": "ㅞ"
                case "ㅜ": "ㅠ"
                default: moeum
                }
            case "ㅟ":
                switch nextMoeum {
                case "ㅓ": "ㅝ"
                case "ㅜ", "ㅡL", "ㅡR": "ㅠ"
                case "ㅏ": "ㅑ"
                default: moeum
                }
            case "ㅡL":
                switch nextMoeum {
                case "ㅏ", "ㅜ": "ㅡLㅜ"
                case "ㅓ", "ㅗ": "ㅡLㅓ"
                case "ㅣL", "ㅣR": "ㅢ"
                default: moeum
                }
            case "ㅡLㅓ":
                switch nextMoeum {
                case "ㅓ", "ㅗ": "ㅓ"
                case "ㅣL", "ㅣR": "ㅢ"
                default: moeum
                }
            case "ㅡLㅜ":
                switch nextMoeum {
                case "ㅏ", "ㅜ": "ㅜ"
                case "ㅣL", "ㅣR": "ㅢ"
                default: moeum
                }
            case "ㅡR":
                switch nextMoeum {
                case "ㅏ", "ㅗ": "ㅡRㅏ"
                case "ㅓ", "ㅜ": "ㅡRㅜ"
                case "ㅣL", "ㅣR": "ㅢ"
                default: moeum
                }
            case "ㅡRㅏ":
                switch nextMoeum {
                case "ㅏ", "ㅗ": "ㅏ"
                case "ㅣL", "ㅣR": "ㅢ"
                default: moeum
                }
            case "ㅡRㅜ":
                switch nextMoeum {
                case "ㅓ", "ㅜ": "ㅜ"
                case "ㅣL", "ㅣR": "ㅢ"
                default: moeum
                }
            case "ㅣL":
                switch nextMoeum {
                case "ㅏ", "ㅗ": "ㅣLㅗ"
                case "ㅓ", "ㅜ": "ㅣLㅓ"
                default: moeum
                }
            case "ㅣLㅓ":
                switch nextMoeum {
                case "ㅓ", "ㅜ": "ㅓ"
                default: moeum
                }
            case "ㅣLㅗ":
                switch nextMoeum {
                case "ㅏ", "ㅗ": "ㅗ"
                default: moeum
                }
            case "ㅣR":
                switch nextMoeum {
                case "ㅏ", "ㅜ": "ㅣRㅏ"
                case "ㅓ", "ㅗ": "ㅣRㅗ"
                default: moeum
                }
            case "ㅣRㅏ":
                switch nextMoeum {
                case "ㅏ", "ㅜ": "ㅏ"
                default: moeum
                }
            case "ㅣRㅗ":
                switch nextMoeum {
                case "ㅓ", "ㅗ": "ㅗ"
                default: moeum
                }
            case nil:
                nextMoeum
            default:
                moeum
            }
        }
        return moeum.map { String($0.prefix(1)) }
    }
}
