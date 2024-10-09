import Preferences
import SuggestionBasic
import XCTest
import XcodeInspector

public class DisabledLanguageListTests: XCTestCase {

    var savedDisabledList: [String] = []

    public override func setUp() {
        savedDisabledList = UserDefaults.shared.value(for: \.suggestionFeatureDisabledLanguageList)
        UserDefaults.shared.set(["yaml", "plaintext"], for: \.suggestionFeatureDisabledLanguageList)
    }

    public override func tearDown() {
        UserDefaults.shared.set(savedDisabledList, for: \.suggestionFeatureDisabledLanguageList)
    }

    // MARK: - isEnabled

    public func testIsEnabled_ReturnsTrue_ForLanguageNotOnDisabledList() {
        XCTAssertTrue(DisabledLanguageList.shared.isEnabled(.builtIn(.swift)))
    }

    public func testIsEnabled_ReturnsFalse_ForLanguageOnDisabledList() {
        XCTAssertFalse(DisabledLanguageList.shared.isEnabled(.plaintext))
    }

    // MARK: - enable

    public func testEnable_RemovesLanguageFromDisabledList() {
        DisabledLanguageList.shared.enable(.plaintext)

        XCTAssertEqual(DisabledLanguageList.shared.list, ["yaml"])
    }

    public func testEnable_IgnoresLanguageNotOnDisabledList() {
        DisabledLanguageList.shared.enable(.builtIn(.swift))

        XCTAssertEqual(DisabledLanguageList.shared.list, ["yaml", "plaintext"])
    }

    // MARK: - disable

    public func testEnable_AddsLanguageToDisabledList() {
        DisabledLanguageList.shared.disable(.builtIn(.scala))

        XCTAssertEqual(DisabledLanguageList.shared.list, ["yaml", "plaintext", "scala"])
    }

    public func testEnable_IgnoresLanguageOnDisabledList() {
        DisabledLanguageList.shared.disable(.plaintext)

        XCTAssertEqual(DisabledLanguageList.shared.list, ["yaml", "plaintext"])
    }
}
