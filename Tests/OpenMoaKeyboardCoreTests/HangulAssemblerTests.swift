import XCTest
@testable import OpenMoaKeyboardCore

final class HangulAssemblerTests: XCTestCase {
    func testAssembleSimpleHangul() {
        let assembler = HangulAssembler()
        XCTAssertNil(assembler.appendJamo("ㄴ"))
        XCTAssertEqual(assembler.unresolved, "ㄴ")
        XCTAssertNil(assembler.appendJamo("ㅡ"))
        XCTAssertEqual(assembler.unresolved, "느")
        XCTAssertNil(assembler.appendJamo("ㆍ"))
        XCTAssertEqual(assembler.unresolved, "누")
        XCTAssertNil(assembler.appendJamo("ㆍ"))
        XCTAssertEqual(assembler.unresolved, "뉴")
        XCTAssertNil(assembler.appendJamo("ㅇ"))
        XCTAssertEqual(assembler.unresolved, "늉")
        XCTAssertEqual(assembler.appendJamo("ㄱ"), "늉")
        XCTAssertEqual(assembler.unresolved, "ㄱ")
    }

    func testAssembleSimpleHangulWithAraea() {
        let assembler = HangulAssembler()
        XCTAssertNil(assembler.appendJamo("ㄴ"))
        XCTAssertEqual(assembler.unresolved, "ㄴ")
        XCTAssertNil(assembler.appendJamo("ㆍ"))
        XCTAssertEqual(assembler.unresolved, "ㄴㆍ")
        XCTAssertNil(assembler.appendJamo("ㆍ"))
        XCTAssertEqual(assembler.unresolved, "ㄴᆢ")
        XCTAssertNil(assembler.appendJamo("ㅣ"))
        XCTAssertEqual(assembler.unresolved, "녀")
    }

    func testAssembleComplexHangul() {
        let assembler = HangulAssembler()
        XCTAssertNil(assembler.appendJamo("ㅂ"))
        XCTAssertEqual(assembler.unresolved, "ㅂ")
        XCTAssertNil(assembler.appendJamo("ㅜ"))
        XCTAssertEqual(assembler.unresolved, "부")
        XCTAssertNil(assembler.appendJamo("ㆍ"))
        XCTAssertEqual(assembler.unresolved, "뷰")
        XCTAssertNil(assembler.appendJamo("ㅣ"))
        XCTAssertEqual(assembler.unresolved, "붜")
        XCTAssertNil(assembler.appendJamo("ㅣ"))
        XCTAssertEqual(assembler.unresolved, "붸")
        XCTAssertNil(assembler.appendJamo("ㄹ"))
        XCTAssertEqual(assembler.unresolved, "뷀")
        XCTAssertNil(assembler.appendJamo("ㄱ"))
        XCTAssertEqual(assembler.unresolved, "뷁")
        XCTAssertEqual(assembler.appendJamo("ㄱ"), "뷁")
        XCTAssertEqual(assembler.unresolved, "ㄱ")
    }

    func testDisassembleJongSeong() {
        let assembler = HangulAssembler()
        _ = assembler.appendJamo("ㅂ")
        _ = assembler.appendJamo("ㅜ")
        _ = assembler.appendJamo("ㆍ")
        _ = assembler.appendJamo("ㅣ")
        _ = assembler.appendJamo("ㅣ")
        _ = assembler.appendJamo("ㄹ")
        _ = assembler.appendJamo("ㄱ")
        XCTAssertEqual(assembler.appendJamo("ㅣ"), "뷀")
        XCTAssertEqual(assembler.unresolved, "기")
    }

    func testDisassembleJongSeongWithAraea() {
        let assembler = HangulAssembler()
        _ = assembler.appendJamo("ㅂ")
        _ = assembler.appendJamo("ㅜ")
        _ = assembler.appendJamo("ㆍ")
        _ = assembler.appendJamo("ㅣ")
        _ = assembler.appendJamo("ㅣ")
        _ = assembler.appendJamo("ㄹ")
        _ = assembler.appendJamo("ㄱ")
        XCTAssertEqual(assembler.appendJamo("ㆍ"), "뷀")
        XCTAssertEqual(assembler.unresolved, "ㄱㆍ")
    }

    func testBackspaceDeletesFromVowelFirstWhenEnabled() {
        let assembler = HangulAssembler()
        _ = assembler.appendJamo("ㄱ")
        _ = assembler.appendJamo("ㅏ")

        assembler.removeForBackspace(deleteStartsWithVowel: true)

        XCTAssertEqual(assembler.unresolved, "ㄱ")
    }

    func testBackspaceDeletesWholeSyllableWhenDisabledWithoutJongseong() {
        let assembler = HangulAssembler()
        _ = assembler.appendJamo("ㄱ")
        _ = assembler.appendJamo("ㅏ")

        assembler.removeForBackspace(deleteStartsWithVowel: false)

        XCTAssertNil(assembler.unresolved)
    }

    func testBackspaceStillDeletesOnlyJongseongWhenDisabled() {
        let assembler = HangulAssembler()
        _ = assembler.appendJamo("ㄱ")
        _ = assembler.appendJamo("ㅏ")
        _ = assembler.appendJamo("ㅇ")

        assembler.removeForBackspace(deleteStartsWithVowel: false)

        XCTAssertEqual(assembler.unresolved, "가")
    }

    func testBackspaceDisassemblesComplexJongseongStepByStep() {
        let assembler = HangulAssembler()
        _ = assembler.appendJamo("ㅇ")
        _ = assembler.appendJamo("ㅏ")
        _ = assembler.appendJamo("ㄹ")
        _ = assembler.appendJamo("ㅎ")

        assembler.removeForBackspace(deleteStartsWithVowel: false)
        XCTAssertEqual(assembler.unresolved, "알")

        assembler.removeForBackspace(deleteStartsWithVowel: false)
        XCTAssertEqual(assembler.unresolved, "아")
    }

    func testBackspaceDeletesComplexVowelAsWholeWhenEnabled() {
        let assembler = HangulAssembler()
        _ = assembler.appendJamo("ㄱ")
        _ = assembler.appendJamo("ㅗ")
        _ = assembler.appendJamo("ㅣ")

        assembler.removeForBackspace(deleteStartsWithVowel: true)

        XCTAssertEqual(assembler.unresolved, "ㄱ")
    }
}
