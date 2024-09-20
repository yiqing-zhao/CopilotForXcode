import ConversationTab
import ChatService
import ChatTab
import Foundation
import PromptToCodeService
import SuggestionBasic
import SuggestionWidget
import XcodeInspector

enum ChatTabFactory {
    static func chatTabBuilderCollection() -> [ChatTabBuilderCollection] {
        func folderIfNeeded(
            _ builders: [any ChatTabBuilder],
            title: String
        ) -> ChatTabBuilderCollection? {
            if builders.count > 1 {
                return .folder(title: title, kinds: builders.map(ChatTabKind.init))
            }
            if let first = builders.first { return .kind(ChatTabKind(first)) }
            return nil
        }

        return [
            folderIfNeeded(ConversationTab.chatBuilders(), title: ConversationTab.name),
        ].compactMap { $0 }
    }
}
