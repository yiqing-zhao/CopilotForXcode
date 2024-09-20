import Foundation
import ChatAPIService

public final class ContextAwareAutoManagedChatMemory: ChatMemory {
    private let memory: AutoManagedChatMemory
    weak var chatService: ChatService?

    public var history: [ChatMessage] {
        get async { await memory.history }
    }

    func observeHistoryChange(_ observer: @escaping () -> Void) {
        memory.observeHistoryChange(observer)
    }

    init() {
        memory = AutoManagedChatMemory(
            systemPrompt: ""
        )
    }

    public func mutateHistory(_ update: (inout [ChatMessage]) -> Void) async {
        await memory.mutateHistory(update)
    }
}

