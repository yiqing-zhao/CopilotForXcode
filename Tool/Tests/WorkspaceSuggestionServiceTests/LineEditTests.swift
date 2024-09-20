import SuggestionBasic
import WorkspaceSuggestionService
import XCTest

final class LineEditTests: XCTestCase {

    func lineAndCursorPos(from str: String) -> (String, CursorPosition) {
        let parts = str.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        let pos = CursorPosition(line: 0, character: parts.first?.count ?? 0)
        return (parts.joined(), pos)
    }

    func suggestion(_ line: String, rangeLength: Int = 0) -> CodeSuggestion {
        let (text, position) = lineAndCursorPos(from: line)
        return CodeSuggestion(
            id: "",
            text: text,
            position: position,
            range: .init(startPair: (0, 0), endPair: (0, rangeLength))
        )
    }

    func edit(from: String, to: String, suggested: String) -> LineEdit {
        // replacement range is the full length of the original line (minus line ending and cursor placeholder)
        return edit(from: from, to: to, suggested: suggested, rangeLength: max(0, from.count - 2))
    }

    func edit(from: String, to: String, suggested: String, rangeLength: Int) -> LineEdit {
        let (fromLine, fromPos) = lineAndCursorPos(from: from)
        let (toLine, toPos) = lineAndCursorPos(from: to)

        return LineEdit(
            snapshot: .init(
                lines: [fromLine],
                cursorPosition: fromPos
            ),
            suggestion: suggestion(suggested, rangeLength: rangeLength),
            lines: [toLine],
            cursor: toPos
        )
    }

    // MARK: .init

    func testInit_EmptyLine() throws {
        let edit = edit(from: "|", to: "|", suggested: "|// hello")

        XCTAssertEqual(edit.line, "")
        XCTAssertEqual(edit.userEntered, "")
        XCTAssertEqual(edit.head, "")
        XCTAssertEqual(edit.tail, "")
    }

    func testInit_NoTail() throws {
        let edit = edit(from: "let one |\n", to: "let one =|\n", suggested: "let one |= 1")

        XCTAssertEqual(edit.line, "let one =")
        XCTAssertEqual(edit.userEntered, "let one =")
        XCTAssertEqual(edit.head, "let one =")
        XCTAssertEqual(edit.tail, "")
    }

    func testInit_PreservesExistingTail() throws {
        let edit = edit(
            from: "let fourTuple = (1, |)\n",
            to: "let fourTuple = (1, 2|)\n",
            suggested: "let fourTuple = (1, |2, 3, 4)"
        )

        XCTAssertEqual(edit.line, "let fourTuple = (1, 2)")
        XCTAssertEqual(edit.userEntered, "let fourTuple = (1, 2")
        XCTAssertEqual(edit.head, "let fourTuple = (1, 2")
        XCTAssertEqual(edit.tail, ")")
    }

    func testInit_NewBraceCompletionIncludedInTail() throws {
        let edit = edit(
            from: "let nestedTuple = (1, |)\n",
            to: "let nestedTuple = (1, (2, (3|)))\n",
            suggested: "let nestedTuple = (1, |(2, (3, 4)))"
        )

        XCTAssertEqual(edit.line, "let nestedTuple = (1, (2, (3)))")
        XCTAssertEqual(edit.userEntered, "let nestedTuple = (1, (2, (3")
        XCTAssertEqual(edit.head, "let nestedTuple = (1, (2, (3")
        XCTAssertEqual(edit.tail, ")))")
    }

    func testInit_NonBraceCompletionNotIncludedInTail() throws {
        let edit = edit(
            from: "let nestedTuple = (1, |)\n",
            to: "let nestedTuple = (1, (|2))\n",
            suggested: "let nestedTuple = (1, |(2, (3, 4)))"
        )

        XCTAssertEqual(edit.line, "let nestedTuple = (1, (2))")
        XCTAssertEqual(edit.userEntered, "let nestedTuple = (1, (2")
        XCTAssertEqual(edit.head, "let nestedTuple = (1, (")
        XCTAssertEqual(edit.tail, "))")
    }

    // MARK: .updateSuggestions

    func testUpdateSuggestions_WithNoChanges_ReturnsSameSuggestions() {
        let edit = edit(from: "|\n", to: "|\n", suggested: "|// hello")

        let suggestions = [suggestion("|// hello"), suggestion("|// hello there")]
        let updated = edit.updateSuggestions(suggestions)

        XCTAssertEqual(updated, suggestions)
    }

    func testUpdateSuggestions_WithTypingIntoSuggetion_AdjustsCursorPositionAndRange() {
        let edit = edit(from: "|\n", to: "//|\n", suggested: "|// hello")

        let suggestions = [suggestion("|// hello"), suggestion("|// hello there")]
        let updated = edit.updateSuggestions(suggestions)

        XCTAssertEqual(updated, [
            suggestion("//| hello", rangeLength: 2),
            suggestion("//| hello there", rangeLength: 2)
        ])
    }

    func testUpdateSuggestions_WithSameTail_PreservesSelectedRange() {
        let edit = edit(
            from: "let pos = (1|)\n",
            to: "let pos = (1, |)\n",
            suggested: "let pos = (1|, 1)"
        )

        let updated = edit.updateSuggestions([edit.suggestion])

        XCTAssertEqual(updated, [suggestion("let pos = (1, |1)", rangeLength: 15)])
    }

    func testUpdateSuggestions_WithPartialLineRange_PreservesUnselectedPortion() {
        let edit = edit(
            from: "let pos = (1|) //\n",
            to: "let pos = (1, |) //\n",
            suggested: "let pos = (1|, 1)",
            rangeLength: 13
        )

        let updated = edit.updateSuggestions([edit.suggestion])

        XCTAssertEqual(updated, [suggestion("let pos = (1, |1)", rangeLength: 15)])
    }

    func testUpdateSuggestions_WithNewBraceCompletion_ExtendsSelectedRange() {
        let edit = edit(
            from: "let nested = (1|)\n",
            to: "let nested = (1, (2, |))\n",
            suggested: "let nested = (1|, (2, 3))"
        )

        let updated = edit.updateSuggestions([edit.suggestion])

        XCTAssertEqual(updated, [suggestion("let nested = (1, (2, |3))", rangeLength: 23)])
    }
}
