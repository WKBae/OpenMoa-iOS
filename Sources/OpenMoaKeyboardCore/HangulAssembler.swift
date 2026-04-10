import Foundation

public final class HangulAssembler {
    private var jamoList: [String] = []

    public init() {}

    private var jaeumSet: Set<String> {
        Set(HangulUnicode.chosungList + [
            "ㄳ", "ㄵ", "ㄶ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅄ",
        ])
    }

    private var moeumSet: Set<String> {
        Set(HangulUnicode.jungsungList + ["ㆍ", "ᆢ"])
    }

    private func assembleLastJongseongIfPossible(_ jamo: String) -> Bool {
        guard jaeumSet.contains(jamo), jamoList.count == 3 else {
            return false
        }

        let lastJamo = jamoList.removeLast()
        let assembled = switch lastJamo {
        case "ㄱ":
            jamo == "ㅅ" ? "ㄳ" : lastJamo
        case "ㄴ":
            switch jamo {
            case "ㅈ": "ㄵ"
            case "ㅎ": "ㄶ"
            default: lastJamo
            }
        case "ㄹ":
            switch jamo {
            case "ㄱ": "ㄺ"
            case "ㅁ": "ㄻ"
            case "ㅂ": "ㄼ"
            case "ㅅ": "ㄽ"
            case "ㅌ": "ㄾ"
            case "ㅍ": "ㄿ"
            case "ㅎ": "ㅀ"
            default: lastJamo
            }
        case "ㅂ":
            jamo == "ㅅ" ? "ㅄ" : lastJamo
        default:
            lastJamo
        }

        jamoList.append(assembled)
        return assembled != lastJamo
    }

    private func disassembleLastJongseongIfPossible() {
        guard let lastJamo = jamoList.popLast() else {
            return
        }

        let disassembled: [String]
        switch lastJamo {
        case "ㄳ": disassembled = ["ㄱ", "ㅅ"]
        case "ㄵ": disassembled = ["ㄴ", "ㅈ"]
        case "ㄶ": disassembled = ["ㄴ", "ㅎ"]
        case "ㄺ": disassembled = ["ㄹ", "ㄱ"]
        case "ㄻ": disassembled = ["ㄹ", "ㅁ"]
        case "ㄼ": disassembled = ["ㄹ", "ㅂ"]
        case "ㄽ": disassembled = ["ㄹ", "ㅅ"]
        case "ㄾ": disassembled = ["ㄹ", "ㅌ"]
        case "ㄿ": disassembled = ["ㄹ", "ㅍ"]
        case "ㅀ": disassembled = ["ㄹ", "ㅎ"]
        case "ㅄ": disassembled = ["ㅂ", "ㅅ"]
        default: disassembled = [lastJamo]
        }
        jamoList.append(contentsOf: disassembled)
    }

    private func assembleLastMoeumIfPossible(_ jamo: String) -> Bool {
        guard let last = jamoList.last, moeumSet.contains(last) else {
            return false
        }

        _ = jamoList.popLast()
        let assembled = switch last {
        case "ㅏ":
            switch jamo {
            case "ㅣ": "ㅐ"
            case "ㆍ": "ㅑ"
            default: last
            }
        case "ㅐ":
            jamo == "ㆍ" ? "ㅒ" : last
        case "ㅑ":
            jamo == "ㅣ" ? "ㅒ" : last
        case "ㅓ":
            switch jamo {
            case "ㅣ": "ㅔ"
            case "ㆍ": "ㅕ"
            default: last
            }
        case "ㅔ":
            jamo == "ㆍ" ? "ㅖ" : last
        case "ㅕ":
            jamo == "ㅣ" ? "ㅖ" : last
        case "ㅗ":
            switch jamo {
            case "ㅣ": "ㅚ"
            case "ㆍ": "ㅛ"
            default: last
            }
        case "ㅘ":
            jamo == "ㅣ" ? "ㅙ" : last
        case "ㅚ":
            jamo == "ㆍ" ? "ㅘ" : last
        case "ㅜ":
            switch jamo {
            case "ㅣ": "ㅟ"
            case "ㆍ": "ㅠ"
            default: last
            }
        case "ㅝ":
            jamo == "ㅣ" ? "ㅞ" : last
        case "ㅠ":
            jamo == "ㅣ" ? "ㅝ" : last
        case "ㅡ":
            switch jamo {
            case "ㅣ": "ㅢ"
            case "ㆍ": "ㅜ"
            default: last
            }
        case "ㅣ":
            jamo == "ㆍ" ? "ㅏ" : last
        case "ㆍ":
            switch jamo {
            case "ㅡ": "ㅗ"
            case "ㅣ": "ㅓ"
            case "ㆍ": "ᆢ"
            default: last
            }
        case "ᆢ":
            switch jamo {
            case "ㅡ": "ㅛ"
            case "ㅣ": "ㅕ"
            default: last
            }
        default:
            last
        }

        jamoList.append(assembled)
        return assembled != last
    }

    private func resolveJamoList(forceResolve: Bool = false) -> String? {
        do {
            let assembled = try HangulUnicode.assemble(jamoList)
            if assembled.count > 1, let first = assembled.first {
                let disassembled = try HangulUnicode.disassemble(first)
                jamoList.removeFirst(disassembled.count)
                return String(first)
            }
            if forceResolve {
                jamoList.removeAll()
                return assembled
            }
            return nil
        } catch {
            let previous = Array(jamoList.dropLast())
            let resolved = (try? HangulUnicode.assemble(previous)) ?? previous.joined()
            jamoList.removeFirst(previous.count)
            return resolved
        }
    }

    public func appendJamo(_ jamo: String) -> String? {
        if jamoList.isEmpty {
            jamoList.append(jamo)
            return nil
        }

        if moeumSet.contains(jamo) {
            disassembleLastJongseongIfPossible()
        }
        if assembleLastMoeumIfPossible(jamo) {
            return nil
        }
        if assembleLastJongseongIfPossible(jamo) {
            return nil
        }
        if ["ㆍ", "ᆢ"].contains(jamo), let last = jamoList.last, jaeumSet.contains(last) {
            let lastJamo = jamoList.removeLast()
            let resolved = jamoList.isEmpty ? nil : resolveJamoList(forceResolve: true)
            jamoList.append(contentsOf: [lastJamo, jamo])
            return resolved
        }

        jamoList.append(jamo)
        return resolveJamoList()
    }

    public var unresolved: String? {
        guard !jamoList.isEmpty else {
            return nil
        }
        return (try? HangulUnicode.assemble(jamoList)) ?? jamoList.joined()
    }

    public func removeLastJamo() {
        _ = jamoList.popLast()
    }

    public func clear() {
        jamoList.removeAll()
    }
}
