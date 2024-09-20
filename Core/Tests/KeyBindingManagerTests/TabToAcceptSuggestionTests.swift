import Foundation
import XCTest

@testable import Workspace
@testable import KeyBindingManager

class TabToAcceptSuggestionTests: XCTestCase {
    @WorkspaceActor
    func test_should_accept() {
        let fileURL = URL(string: "file:///test")!
        let workspacePool = FakeWorkspacePool()
        workspacePool.setTestFile(fileURL: fileURL)
        let xcodeInspector = FakeThreadSafeAccessToXcodeInspector(
            activeDocumentURL: fileURL,
            hasActiveXcode: true,
            hasFocusedEditor: true
        )
        XCTAssertTrue(
            TabToAcceptSuggestion.shouldAcceptSuggestion(
                event: CGEvent(keyboardEventSource: nil, virtualKey: 48, keyDown: true)!,
                workspacePool: workspacePool,
                xcodeInspector: xcodeInspector
            )
        )
    }

    @WorkspaceActor
    func test_should_not_accept_without_suggestion() {
        let fileURL = URL(string: "file:///test")!
        let workspacePool = FakeWorkspacePool()
        let xcodeInspector = FakeThreadSafeAccessToXcodeInspector(
            activeDocumentURL: fileURL,
            hasActiveXcode: true,
            hasFocusedEditor: true
        )
        XCTAssertFalse(
            TabToAcceptSuggestion.shouldAcceptSuggestion(
                event: CGEvent(keyboardEventSource: nil, virtualKey: 48, keyDown: true)!,
                workspacePool: workspacePool,
                xcodeInspector: xcodeInspector
            )
        )
    }

    @WorkspaceActor
    func test_should_not_accept_without_editor_focused() {
        let fileURL = URL(string: "file:///test")!
        let workspacePool = FakeWorkspacePool()
        workspacePool.setTestFile(fileURL: fileURL)
        let xcodeInspector = FakeThreadSafeAccessToXcodeInspector(
            activeDocumentURL: fileURL,
            hasActiveXcode: true,
            hasFocusedEditor: false
        )
        XCTAssertFalse(
            TabToAcceptSuggestion.shouldAcceptSuggestion(
                event: CGEvent(keyboardEventSource: nil, virtualKey: 48, keyDown: true)!,
                workspacePool: workspacePool,
                xcodeInspector: xcodeInspector
            )
        )
    }

    @WorkspaceActor
    func test_should_not_accept_without_active_xcode() {
        let fileURL = URL(string: "file:///test")!
        let workspacePool = FakeWorkspacePool()
        workspacePool.setTestFile(fileURL: fileURL)
        let xcodeInspector = FakeThreadSafeAccessToXcodeInspector(
            activeDocumentURL: fileURL,
            hasActiveXcode: false,
            hasFocusedEditor: true
        )
        XCTAssertFalse(
            TabToAcceptSuggestion.shouldAcceptSuggestion(
                event: createEvent(48),
                workspacePool: workspacePool,
                xcodeInspector: xcodeInspector
            )
        )
    }

    @WorkspaceActor
    func test_should_not_accept_without_active_document() {
        let fileURL = URL(string: "file:///test")!
        let workspacePool = FakeWorkspacePool()
        workspacePool.setTestFile(fileURL: fileURL)
        let xcodeInspector = FakeThreadSafeAccessToXcodeInspector(
            activeDocumentURL: nil,
            hasActiveXcode: true,
            hasFocusedEditor: true
        )
        XCTAssertFalse(
            TabToAcceptSuggestion.shouldAcceptSuggestion(
                event: createEvent(48),
                workspacePool: workspacePool,
                xcodeInspector: xcodeInspector
            )
        )
    }

    @WorkspaceActor
    func test_should_not_accept_with_shift() {
        let fileURL = URL(string: "file:///test")!
        let workspacePool = FakeWorkspacePool()
        workspacePool.setTestFile(fileURL: fileURL)
        let xcodeInspector = FakeThreadSafeAccessToXcodeInspector(
            activeDocumentURL: fileURL,
            hasActiveXcode: true,
            hasFocusedEditor: true
        )
        XCTAssertFalse(
            TabToAcceptSuggestion.shouldAcceptSuggestion(
                event: createEvent(48, flags: .maskShift),
                workspacePool: workspacePool,
                xcodeInspector: xcodeInspector
            )
        )
    }

    @WorkspaceActor
    func test_should_not_accept_with_command() {
        let fileURL = URL(string: "file:///test")!
        let workspacePool = FakeWorkspacePool()
        workspacePool.setTestFile(fileURL: fileURL)
        let xcodeInspector = FakeThreadSafeAccessToXcodeInspector(
            activeDocumentURL: fileURL,
            hasActiveXcode: true,
            hasFocusedEditor: true
        )
        XCTAssertFalse(
            TabToAcceptSuggestion.shouldAcceptSuggestion(
                event: createEvent(48, flags: .maskCommand),
                workspacePool: workspacePool,
                xcodeInspector: xcodeInspector
            )
        )
    }

    @WorkspaceActor
    func test_should_not_accept_with_control() {
        let fileURL = URL(string: "file:///test")!
        let workspacePool = FakeWorkspacePool()
        workspacePool.setTestFile(fileURL: fileURL)
        let xcodeInspector = FakeThreadSafeAccessToXcodeInspector(
            activeDocumentURL: fileURL,
            hasActiveXcode: true,
            hasFocusedEditor: true
        )
        XCTAssertFalse(
            TabToAcceptSuggestion.shouldAcceptSuggestion(
                event: createEvent(48, flags: .maskControl),
                workspacePool: workspacePool,
                xcodeInspector: xcodeInspector
            )
        )
    }

    @WorkspaceActor
    func test_should_not_accept_with_help() {
        let fileURL = URL(string: "file:///test")!
        let workspacePool = FakeWorkspacePool()
        workspacePool.setTestFile(fileURL: fileURL)
        let xcodeInspector = FakeThreadSafeAccessToXcodeInspector(
            activeDocumentURL: fileURL,
            hasActiveXcode: true,
            hasFocusedEditor: true
        )
        XCTAssertFalse(
            TabToAcceptSuggestion.shouldAcceptSuggestion(
                event: createEvent(48, flags: .maskHelp),
                workspacePool: workspacePool,
                xcodeInspector: xcodeInspector
            )
        )
    }

    @WorkspaceActor
    func test_should_not_accept_without_tab() {
        let fileURL = URL(string: "file:///test")!
        let workspacePool = FakeWorkspacePool()
        workspacePool.setTestFile(fileURL: fileURL)
        let xcodeInspector = FakeThreadSafeAccessToXcodeInspector(
            activeDocumentURL: fileURL,
            hasActiveXcode: true,
            hasFocusedEditor: true
        )
        XCTAssertFalse(
            TabToAcceptSuggestion.shouldAcceptSuggestion(
                event: createEvent(50),
                workspacePool: workspacePool,
                xcodeInspector: xcodeInspector
            )
        )
    }
}

private func createEvent(_ keyCode: CGKeyCode, flags: CGEventFlags = []) -> CGEvent {
    let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)!
    event.flags = flags
    return event
}

private struct FakeThreadSafeAccessToXcodeInspector: ThreadSafeAccessToXcodeInspectorProtocol {
    let activeDocumentURL: URL?
    let hasActiveXcode: Bool
    let hasFocusedEditor: Bool
}

private class FakeWorkspacePool: WorkspacePool {
    private var fileURL: URL?
    private var filespace: Filespace?
    
    @WorkspaceActor
    func setTestFile(fileURL: URL) {
        self.fileURL = fileURL
        self.filespace = Filespace(fileURL: fileURL, onSave: {_ in }, onClose: {_ in })
        guard let filespace = self.filespace else { return }
        filespace.setSuggestions([.init(id: "id", text: "test", position: .zero, range: .zero)])
    }
    
    override func fetchFilespaceIfExisted(fileURL: URL) -> Filespace? {
        guard fileURL == self.fileURL else { return .none }
        return filespace
    }
}

