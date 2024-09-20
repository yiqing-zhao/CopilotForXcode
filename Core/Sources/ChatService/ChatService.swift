import ChatAPIService
import Combine
import Foundation
import GitHubCopilotService
import Preferences
import ConversationServiceProvider
import BuiltinExtension

public protocol ChatServiceType {
    var memory: ContextAwareAutoManagedChatMemory { get set }
    func send(_ id: String, content: String) async throws
    func stopReceivingMessage() async
    func upvote(_ id: String, _ rating: ConversationRating) async
    func downvote(_ id: String, _ rating: ConversationRating) async
    func copyCode(_ id: String) async
}

public final class ChatService: ChatServiceType, ObservableObject {
    
    public var memory: ContextAwareAutoManagedChatMemory
    @Published public internal(set) var chatHistory: [ChatMessage] = []
    @Published public internal(set) var isReceivingMessage = false

    private let conversationProvider: ConversationServiceProvider?
    private let conversationProgressHandler: ConversationProgressHandler
    private var cancellables = Set<AnyCancellable>()
    private var activeRequestId: String?
    private var conversationId: String?
    
    init(provider: any ConversationServiceProvider,
         memory: ContextAwareAutoManagedChatMemory = ContextAwareAutoManagedChatMemory(),
         conversationProgressHandler: ConversationProgressHandler = ConversationProgressHandlerImpl.shared) {
        self.memory = memory
        self.conversationProvider = provider
        self.conversationProgressHandler = conversationProgressHandler
        memory.chatService = self
        
        subscribeToNotifications()
    }
    
    private func subscribeToNotifications() {
        memory.observeHistoryChange { [weak self] in
            Task { [weak self] in
                guard let memory = self?.memory else { return }
                self?.chatHistory = await memory.history
            }
        }
        
        conversationProgressHandler.onBegin.sink { [weak self] (token, progress) in
            self?.handleProgressBegin(token: token, progress: progress)
        }.store(in: &cancellables)
        
        conversationProgressHandler.onProgress.sink { [weak self] (token, progress) in
            self?.handleProgressReport(token: token, progress: progress)
        }.store(in: &cancellables)
        
        conversationProgressHandler.onEnd.sink { [weak self] (token, progress) in
            self?.handleProgressEnd(token: token, progress: progress)
        }.store(in: &cancellables)
    }
    
    public static func service() -> ChatService {
        let provider = BuiltinExtensionConversationServiceProvider(
            extension: GitHubCopilotExtension.self
        )
        return ChatService(provider: provider)
    }
    
    public func send(_ id: String, content: String) async throws {
        guard activeRequestId == nil else { return }
        let workDoneToken = UUID().uuidString
        activeRequestId = workDoneToken
        
        await memory.appendMessage(ChatMessage(id: id, role: .user, content: content, summary: nil, references: []))
        
        let request = ConversationRequest(workDoneToken: workDoneToken,
                                          content: content, workspaceFolder: "", skills: [])
        try await send(request)
    }

    public func sendAndWait(_ id: String, content: String) async throws -> String {
        try await send(id, content: content)
        if let reply = await memory.history.last(where: { $0.role == .assistant })?.content {
            return reply
        }
        return ""
    }

    public func stopReceivingMessage() async {
        if let activeRequestId = activeRequestId {
            do {
                try await conversationProvider?.stopReceivingMessage(activeRequestId)
            } catch {
                print("Failed to cancel ongoing request with WDT: \(activeRequestId)")
            }
        }
        resetOngoingRequest()
    }

    public func clearHistory() async {
        await memory.clearHistory()
        if let activeRequestId = activeRequestId {
            do {
                try await conversationProvider?.stopReceivingMessage(activeRequestId)
            } catch {
                print("Failed to cancel ongoing request with WDT: \(activeRequestId)")
            }
        }
        resetOngoingRequest()
    }

    public func deleteMessage(id: String) async {
        await memory.removeMessage(id)
    }

    public func resendMessage(id: String) async throws {
        if let message = (await memory.history).first(where: { $0.id == id })
        {
            do {
                try await send(id, content: message.content)
            } catch {
                print("Failed to resend message")
            }
        }
    }

    public func setMessageAsExtraPrompt(id: String) async {
        if let message = (await memory.history).first(where: { $0.id == id })
        {
            await mutateHistory { history in
                history.append(.init(
                    role: .assistant,
                    content: message.content
                ))
            }
        }
    }

    public func mutateHistory(_ mutator: @escaping (inout [ChatMessage]) -> Void) async {
        await memory.mutateHistory(mutator)
    }

    public func handleCustomCommand(_ command: CustomCommand) async throws {
        struct CustomCommandInfo {
            var specifiedSystemPrompt: String?
            var extraSystemPrompt: String?
            var sendingMessageImmediately: String?
            var name: String?
        }

        let info: CustomCommandInfo? = {
            switch command.feature {
            case let .chatWithSelection(extraSystemPrompt, prompt, useExtraSystemPrompt):
                let updatePrompt = useExtraSystemPrompt ?? true
                return .init(
                    extraSystemPrompt: updatePrompt ? extraSystemPrompt : nil,
                    sendingMessageImmediately: prompt,
                    name: command.name
                )
            case let .customChat(systemPrompt, prompt):
                return .init(
                    specifiedSystemPrompt: systemPrompt,
                    extraSystemPrompt: "",
                    sendingMessageImmediately: prompt,
                    name: command.name
                )
            case .promptToCode: return nil
            case .singleRoundDialog: return nil
            }
        }()

        guard let info else { return }

        let templateProcessor = CustomCommandTemplateProcessor()

        if info.specifiedSystemPrompt != nil || info.extraSystemPrompt != nil {
            await mutateHistory { history in
                history.append(.init(
                    role: .assistant,
                    content: ""
                ))
            }
        }

        if let sendingMessageImmediately = info.sendingMessageImmediately,
           !sendingMessageImmediately.isEmpty
        {
            try await send(UUID().uuidString, content: templateProcessor.process(sendingMessageImmediately))
        }
    }
    
    public func upvote(_ id: String, _ rating: ConversationRating) async {
        try? await conversationProvider?.rateConversation(turnId: id, rating: rating)
    }
    
    public func downvote(_ id: String, _ rating: ConversationRating) async {
        try? await conversationProvider?.rateConversation(turnId: id, rating: rating)
    }
    
    public func copyCode(_ id: String) async {
        // TODO: pass copy code info to Copilot server
    }

    public func handleSingleRoundDialogCommand(
        systemPrompt: String?,
        overwriteSystemPrompt: Bool,
        prompt: String
    ) async throws -> String {
        let templateProcessor = CustomCommandTemplateProcessor()
        return try await sendAndWait(UUID().uuidString, content: templateProcessor.process(prompt))
    }
    
    private func handleProgressBegin(token: String, progress: ConversationProgress) {
        guard let workDoneToken = activeRequestId, workDoneToken == token else { return }
        conversationId = progress.conversationId
        
        Task {
            if var lastUserMessage = await memory.history.last(where: { $0.role == .user }) {
                lastUserMessage.turnId = progress.turnId
            }
        }
    }

    private func handleProgressReport(token: String, progress: ConversationProgress) {
        guard let workDoneToken = activeRequestId, workDoneToken == token, let reply = progress.reply else { return }
        
        Task {
            let message = ChatMessage(id: progress.turnId, role: .assistant, content: reply)
            await memory.appendMessage(message)
        }
    }

    private func handleProgressEnd(token: String, progress: ConversationProgress) {
        guard let workDoneToken = activeRequestId, workDoneToken == token else { return }
        resetOngoingRequest()
    }
    
    private func resetOngoingRequest() {
        activeRequestId = nil
        isReceivingMessage = false
    }
    
    private func send(_ request: ConversationRequest) async throws {
        guard !isReceivingMessage else { throw CancellationError() }
        isReceivingMessage = true
        
        do {
            if let conversationId = conversationId {
                try await conversationProvider?.createTurn(with: conversationId, request: request)
            } else {
                try await conversationProvider?.createConversation(request)
            }
        } catch {
            resetOngoingRequest()
            throw error
        }
    }
}

