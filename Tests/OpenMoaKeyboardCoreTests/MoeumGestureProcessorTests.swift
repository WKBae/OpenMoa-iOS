import XCTest
@testable import OpenMoaKeyboardCore

final class MoeumGestureProcessorTests: XCTestCase {
    func testYaGesture() {
        let processor = MoeumGestureProcessor()
        processor.appendMoeum("ㅏ")
        processor.appendMoeum("ㅓ")
        processor.appendMoeum("ㅏ")
        XCTAssertEqual(processor.resolveMoeumList(), "ㅑ")
    }
}
