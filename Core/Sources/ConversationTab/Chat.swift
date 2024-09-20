import ChatService
import ComposableArchitecture
import Foundation
import ChatAPIService
import Preferences
import Terminal
import ConversationServiceProvider

public struct DisplayedChatMessage: Equatable {
    public enum Role: Equatable {
        case user
        case assistant
        case tool
        case ignored
    }

    public struct Reference: Equatable {
        public typealias Kind = ChatMessage.Reference.Kind

        public var title: String
        public var subtitle: String
        public var uri: String
        public var startLine: Int?
        public var kind: Kind

        public init(
            title: String,
            subtitle: String,
            uri: String,
            startLine: Int?,
            kind: Kind
        ) {
            self.title = title
            self.subtitle = subtitle
            self.uri = uri
            self.startLine = startLine
            self.kind = kind
        }
    }

    public var id: String
    public var role: Role
    public var text: String
    public var references: [Reference] = []

    public init(id: String, role: Role, text: String, references: [Reference]) {
        self.id = id
        self.role = role
        self.text = text
        self.references = references
    }
}

private var isPreview: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

@Reducer
struct Chat {
    public typealias MessageID = String

    @ObservableState
    struct State: Equatable {
        var title: String = "Chat"
        var typedMessage = ""
        var history: [DisplayedChatMessage] = []
        var isReceivingMessage = false
        var chatMenu = ChatMenu.State()
        var focusedField: Field?

        enum Field: String, Hashable {
            case textField
        }
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)

        case appear
        case refresh
        case sendButtonTapped(String)
        case returnButtonTapped
        case stopRespondingButtonTapped
        case clearButtonTap
        case deleteMessageButtonTapped(MessageID)
        case resendMessageButtonTapped(MessageID)
        case setAsExtraPromptButtonTapped(MessageID)
        case focusOnTextField
        case referenceClicked(DisplayedChatMessage.Reference)
        case upvote(MessageID, ConversationRating)
        case downvote(MessageID, ConversationRating)
        case copyCode(MessageID)

        case observeChatService
        case observeHistoryChange
        case observeIsReceivingMessageChange

        case historyChanged
        case isReceivingMessageChanged

        case chatMenu(ChatMenu.Action)
    }

    let service: ChatService
    let id = UUID()

    enum CancelID: Hashable {
        case observeHistoryChange(UUID)
        case observeIsReceivingMessageChange(UUID)
        case sendMessage(UUID)
    }

    @Dependency(\.openURL) var openURL

    var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.chatMenu, action: /Action.chatMenu) {
            ChatMenu(service: service)
        }

        Reduce { state, action in
            switch action {
            case .appear:
                return .run { send in
                    if isPreview { return }
                    await send(.observeChatService)
                    await send(.historyChanged)
                    await send(.isReceivingMessageChanged)
                    await send(.focusOnTextField)
                    await send(.refresh)
                }

            case .refresh:
                return .run { send in
                    await send(.chatMenu(.refresh))
                }

            case let .sendButtonTapped(id):
                guard !state.typedMessage.isEmpty else { return .none }
                let message = state.typedMessage
                state.typedMessage = ""
                return .run { _ in
                    try await service.send(id, content: message)
                }.cancellable(id: CancelID.sendMessage(self.id))

            case .returnButtonTapped:
                state.typedMessage += "\n"
                return .none

            case .stopRespondingButtonTapped:
                return .merge(
                    .run { _ in
                        await service.stopReceivingMessage()
                    },
                    .cancel(id: CancelID.sendMessage(id))
                )

            case .clearButtonTap:
                return .run { _ in
                    await service.clearHistory()
                }

            case let .deleteMessageButtonTapped(id):
                return .run { _ in
                    await service.deleteMessage(id: id)
                }

            case let .resendMessageButtonTapped(id):
                return .run { _ in
                    try await service.resendMessage(id: id)
                }

            case let .setAsExtraPromptButtonTapped(id):
                return .run { _ in
                    await service.setMessageAsExtraPrompt(id: id)
                }

            case let .referenceClicked(reference):
                let fileURL = URL(fileURLWithPath: reference.uri)
                return .run { _ in
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        let terminal = Terminal()
                        do {
                            _ = try await terminal.runCommand(
                                "/bin/bash",
                                arguments: [
                                    "-c",
                                    "xed -l \(reference.startLine ?? 0) \"\(reference.uri)\"",
                                ],
                                environment: [:]
                            )
                        } catch {
                            print(error)
                        }
                    } else if let url = URL(string: reference.uri), url.scheme != nil {
                        await openURL(url)
                    }
                }

            case .focusOnTextField:
                state.focusedField = .textField
                return .none

            case .observeChatService:
                return .run { send in
                    await send(.observeHistoryChange)
                    await send(.observeIsReceivingMessageChange)
                }

            case .observeHistoryChange:
                return .run { send in
                    let stream = AsyncStream<Void> { continuation in
                        let cancellable = service.$chatHistory.sink { _ in
                            continuation.yield()
                        }
                        continuation.onTermination = { _ in
                            cancellable.cancel()
                        }
                    }
                    let debouncedHistoryChange = TimedDebounceFunction(duration: 0.2) {
                        await send(.historyChanged)
                    }
                    
                    for await _ in stream {
                        await debouncedHistoryChange()
                    }
                }.cancellable(id: CancelID.observeHistoryChange(id), cancelInFlight: true)

            case .observeIsReceivingMessageChange:
                return .run { send in
                    let stream = AsyncStream<Void> { continuation in
                        let cancellable = service.$isReceivingMessage
                            .sink { _ in
                                continuation.yield()
                            }
                        continuation.onTermination = { _ in
                            cancellable.cancel()
                        }
                    }
                    for await _ in stream {
                        await send(.isReceivingMessageChanged)
                    }
                }.cancellable(
                    id: CancelID.observeIsReceivingMessageChange(id),
                    cancelInFlight: true
                )

            case .historyChanged:
                state.history = service.chatHistory.flatMap { message in
                    var all = [DisplayedChatMessage]()
                    all.append(.init(
                        id: message.id,
                        role: {
                            switch message.role {
                            case .system: return .ignored
                            case .user: return .user
                            case .assistant: return .assistant
                            }
                        }(),
                        text: message.summary ?? message.content,
                        references: message.references.map {
                            .init(
                                title: $0.title,
                                subtitle: $0.subTitle,
                                uri: $0.uri,
                                startLine: $0.startLine,
                                kind: $0.kind
                            )
                        }
                    ))

                    return all
                }

                state.title = {
                    let defaultTitle = "Chat"
                    guard let lastMessageText = state.history
                        .filter({ $0.role == .assistant || $0.role == .user })
                        .last?
                        .text else { return defaultTitle }
                    if lastMessageText.isEmpty { return defaultTitle }
                    let trimmed = lastMessageText
                        .trimmingCharacters(in: .punctuationCharacters)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.starts(with: "```") {
                        return "Code Block"
                    } else {
                        return trimmed
                    }
                }()
                return .none

            case .isReceivingMessageChanged:
                state.isReceivingMessage = service.isReceivingMessage
                return .none

            case .binding:
                return .none

            case .chatMenu:
                return .none
            case let .upvote(id, rating):
                return .run { _ in
                    await service.upvote(id, rating)
                }
            case let .downvote(id, rating):
                return .run { _ in
                    await service.downvote(id, rating)
                }
            case let .copyCode(id):
                return .run { _ in
                    await service.copyCode(id)
                }
            }
        }
    }
}

@Reducer
struct ChatMenu {
    @ObservableState
    struct State: Equatable {
        var systemPrompt: String = ""
        var extraSystemPrompt: String = ""
        var temperatureOverride: Double? = nil
        var chatModelIdOverride: String? = nil
    }

    enum Action: Equatable {
        case appear
        case refresh
        case customCommandButtonTapped(CustomCommand)
    }

    let service: ChatService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appear:
                return .run {
                    await $0(.refresh)
                }

            case .refresh:
                return .none

            case let .customCommandButtonTapped(command):
                return .run { _ in
                    try await service.handleCustomCommand(command)
                }
            }
        }
    }
}

private actor TimedDebounceFunction {
    let duration: TimeInterval
    let block: () async -> Void

    var task: Task<Void, Error>?
    var lastFireTime: Date = .init(timeIntervalSince1970: 0)

    init(duration: TimeInterval, block: @escaping () async -> Void) {
        self.duration = duration
        self.block = block
    }

    func callAsFunction() async {
        task?.cancel()
        if lastFireTime.timeIntervalSinceNow < -duration {
            await fire()
            task = nil
        } else {
            task = Task.detached { [weak self, duration] in
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                await self?.fire()
            }
        }
    }
    
    func fire() async {
        lastFireTime = Date()
        await block()
    }
}
