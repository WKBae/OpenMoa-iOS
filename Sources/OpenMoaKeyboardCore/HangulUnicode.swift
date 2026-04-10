import Foundation

public enum HangulUnicodeError: Error {
    case emptyJamo
    case invalidCharacter
    case invalidChosung(Int)
    case invalidJungsung(Int)
    case invalidJongsung(Int)
    case insufficientJamo
}

public enum HangulUnicode {
    private static let firstHangul = 0xAC00
    private static let lastHangul = 0xD79F

    public static let chosungList = [
        "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ",
        "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ",
    ]

    public static let jungsungList = [
        "ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ",
        "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ",
        "ㅣ",
    ]

    public static let jongsungList = [
        " ", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ",
        "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ",
        "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ",
    ]

    public static func disassemble(_ character: Character) throws -> [String] {
        guard let scalar = character.unicodeScalars.first?.value,
              character.unicodeScalars.count == 1 else {
            throw HangulUnicodeError.invalidCharacter
        }

        guard scalar >= firstHangul && scalar <= lastHangul else {
            throw HangulUnicodeError.invalidCharacter
        }

        let baseCode = Int(scalar) - firstHangul
        let chosungIndex = baseCode / (jongsungList.count * jungsungList.count)
        let jungsungIndex = (baseCode - (jongsungList.count * jungsungList.count * chosungIndex)) / jongsungList.count
        let jongsungIndex = baseCode - (jongsungList.count * jungsungList.count * chosungIndex) - (jongsungList.count * jungsungIndex)

        var jamo = [chosungList[chosungIndex], jungsungList[jungsungIndex]]
        if jongsungIndex > 0 {
            jamo.append(jongsungList[jongsungIndex])
        }
        return jamo
    }

    public static func assemble(_ jamoList: [String]) throws -> String {
        guard !jamoList.isEmpty else {
            throw HangulUnicodeError.emptyJamo
        }

        var result = ""
        var startIndex = 0

        while startIndex < jamoList.count {
            let assembleSize = try nextAssembleSize(in: jamoList, startIndex: startIndex)
            result += try assemble(jamoList, startIndex: startIndex, assembleSize: assembleSize)
            startIndex += assembleSize
        }

        return result
    }

    private static func assemble(
        _ jamoList: [String],
        startIndex: Int,
        assembleSize: Int
    ) throws -> String {
        guard let chosungIndex = chosungList.firstIndex(of: jamoList[startIndex]) else {
            throw HangulUnicodeError.invalidChosung(startIndex + 1)
        }
        guard let jungsungIndex = jungsungList.firstIndex(of: jamoList[startIndex + 1]) else {
            throw HangulUnicodeError.invalidJungsung(startIndex + 2)
        }

        var unicode = firstHangul
        unicode += jongsungList.count * jungsungList.count * chosungIndex
        unicode += jongsungList.count * jungsungIndex

        if assembleSize > 2 {
            guard let jongsungIndex = jongsungList.firstIndex(of: jamoList[startIndex + 2]) else {
                throw HangulUnicodeError.invalidJongsung(startIndex + 3)
            }
            unicode += jongsungIndex
        }

        guard let scalar = UnicodeScalar(unicode) else {
            throw HangulUnicodeError.invalidCharacter
        }
        return String(Character(scalar))
    }

    private static func nextAssembleSize(
        in jamoList: [String],
        startIndex: Int
    ) throws -> Int {
        let remaining = jamoList.count - startIndex
        switch remaining {
        case 4...:
            return jungsungList.contains(jamoList[startIndex + 3]) ? 2 : 3
        case 2, 3:
            return remaining
        default:
            throw HangulUnicodeError.insufficientJamo
        }
    }
}
