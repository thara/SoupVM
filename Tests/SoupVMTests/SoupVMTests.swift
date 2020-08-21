import XCTest
@testable import SoupVM

final class SoupVMTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SoupVM().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
