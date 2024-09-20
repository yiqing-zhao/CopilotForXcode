import XCTest
import SuggestionBasic
import WorkspaceSuggestionService

final class FilespaceSuggestionSnapshotTests: XCTestCase {

    func testSameContent_IsEqual() throws {
        let a = FilespaceSuggestionSnapshot(
            lines: ["one","two",""],
            cursorPosition: CursorPosition(line: 2, character: 0)
        )
        let b = FilespaceSuggestionSnapshot(
            lines: ["one","two",""],
            cursorPosition: CursorPosition(line: 2, character: 0)
        )

        XCTAssertTrue(a == b)
    }

    func testDifferenentContent_IsNotEqual() throws {
        let a = FilespaceSuggestionSnapshot(
            lines: ["one","two",""],
            cursorPosition: CursorPosition(line: 2, character: 0)
        )
        let b = FilespaceSuggestionSnapshot(
            lines: ["on","two",""],
            cursorPosition: CursorPosition(line: 2, character: 0)
        )

        XCTAssertFalse(a == b)
    }

    func testEqualOrCurrentLineDiffers_WithNoChange_ReturnsTrue() throws {
        let a = FilespaceSuggestionSnapshot(
            lines: ["one","two",""],
            cursorPosition: CursorPosition(line: 2, character: 0)
        )
        let b = FilespaceSuggestionSnapshot(
            lines: ["one","two",""],
            cursorPosition: CursorPosition(line: 2, character: 0)
        )

        XCTAssertTrue(a.equalOrOnlyCurrentLineDiffers(comparedTo: b))
    }

    func testEqualOrCurrentLineDiffers_WithOnlyCurrentChange_ReturnsTrue() throws {
        let a = FilespaceSuggestionSnapshot(
            lines: ["one","two",""],
            cursorPosition: CursorPosition(line: 2, character: 0)
        )
        let b = FilespaceSuggestionSnapshot(
            lines: ["one","two","t"],
            cursorPosition: CursorPosition(line: 2, character: 1)
        )

        XCTAssertTrue(a.equalOrOnlyCurrentLineDiffers(comparedTo: b))
    }

    func testEqualOrCurrentLineDiffers_WithPositionChange_ReturnsFalse() throws {
        let a = FilespaceSuggestionSnapshot(
            lines: ["one","two",""],
            cursorPosition: CursorPosition(line: 2, character: 0)
        )
        let b = FilespaceSuggestionSnapshot(
            lines: ["one","two",""],
            cursorPosition: CursorPosition(line: 1, character: 0)
        )

        XCTAssertFalse(a.equalOrOnlyCurrentLineDiffers(comparedTo: b))
    }

    func testEqualOrCurrentLineDiffers_WithPrefixChange_ReturnsFalse() throws {
        let a = FilespaceSuggestionSnapshot(
            lines: ["one","two",""],
            cursorPosition: CursorPosition(line: 2, character: 0)
        )
        let b = FilespaceSuggestionSnapshot(
            lines: ["one","one",""],
            cursorPosition: CursorPosition(line: 2, character: 0)
        )

        XCTAssertFalse(a.equalOrOnlyCurrentLineDiffers(comparedTo: b))
    }

    func testEqualOrCurrentLineDiffers_WithSuffixChange_ReturnsFalse() throws {
        let a = FilespaceSuggestionSnapshot(
            lines: ["one","","three"],
            cursorPosition: CursorPosition(line: 1, character: 0)
        )
        let b = FilespaceSuggestionSnapshot(
            lines: ["one",""],
            cursorPosition: CursorPosition(line: 1, character: 0)
        )

        XCTAssertFalse(a.equalOrOnlyCurrentLineDiffers(comparedTo: b))
    }
}
