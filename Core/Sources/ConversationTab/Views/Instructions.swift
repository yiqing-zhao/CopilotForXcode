import ComposableArchitecture
import Foundation
import MarkdownUI
import SwiftUI

struct Instruction: View {
    let chat: StoreOf<Chat>

    var body: some View {
        WithPerceptionTracking {
            Group {
                Markdown(
                """
                Hello, I am your AI programming assistant. I can identify issues, explain and even improve code.
                """
                )
                .modifier(InstructionModifier())
            }
        }
    }

    struct InstructionModifier: ViewModifier {
        @AppStorage(\.chatFontSize) var chatFontSize

        func body(content: Content) -> some View {
            content
                .textSelection(.enabled)
                .markdownTheme(.instruction(fontSize: chatFontSize))
                .opacity(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                }
        }
    }
}

