import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
public struct SuggestionPanelFeature {
    @ObservableState
    public struct State: Equatable {
        var content: CodeSuggestionProvider?
        var isExpanded: Bool = false
        var colorScheme: ColorScheme = .light
        var alignTopToAnchor = false
        var firstLineIndent: Double = 0
        var lineHeight: Double = 17
        var isPanelDisplayed: Bool = false
        var isPanelOutOfFrame: Bool = false
        var opacity: Double {
            guard isPanelDisplayed else { return 0 }
            if isPanelOutOfFrame { return 0 }
            guard content != nil else { return 0 }
            return 1
        }
    }

    public enum Action: Equatable {
        case noAction
    }

    public var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
