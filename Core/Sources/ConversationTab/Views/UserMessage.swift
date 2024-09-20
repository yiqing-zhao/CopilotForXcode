import ComposableArchitecture
import ChatService
import Foundation
import MarkdownUI
import SharedUIComponents
import SwiftUI

struct UserMessage: View {
    var r: Double { messageBubbleCornerRadius }
    let id: String
    let text: String
    let chat: StoreOf<Chat>
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack() {
            Spacer()
            VStack(alignment: .trailing) {
                ThemedMarkdownText(text)
                    .frame(alignment: .leading)
                    .padding()
            }
            .background {
                RoundedCorners(tl: r, tr: r, bl: r, br: 0)
                    .fill(Color.userChatContentBackground)
            }
            .overlay {
                RoundedCorners(tl: r, tr: r, bl: r, br: 0)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 6)
        }
        .padding(.leading, 8)
        .padding(.trailing, 8)
    }
}

#Preview {
    UserMessage(
        id: "A",
        text: #"""
        Please buy me a coffee!
        | Coffee | Milk |
        |--------|------|
        | Espresso | No |
        | Latte | Yes |
        ```swift
        func foo() {}
        ```
        ```objectivec
        - (void)bar {}
        ```
        """#,
        chat: .init(
            initialState: .init(history: [] as [DisplayedChatMessage], isReceivingMessage: false),
            reducer: { Chat(service: ChatService.service()) }
        )
    )
    .padding()
    .fixedSize(horizontal: true, vertical: true)
}

