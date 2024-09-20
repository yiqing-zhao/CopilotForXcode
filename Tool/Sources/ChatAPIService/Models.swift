import CodableWrappers
import Foundation
import ConversationServiceProvider

public struct ChatMessage: Equatable, Codable {
    public typealias ID = String

    public enum Role: String, Codable, Equatable {
        case system
        case user
        case assistant
    }

    public struct Reference: Codable, Equatable {
        public enum Kind: String, Codable {
            case `class`
            case `struct`
            case `enum`
            case `actor`
            case `protocol`
            case `extension`
            case `case`
            case property
            case `typealias`
            case function
            case method
            case text
            case webpage
            case other
        }

        public var title: String
        public var subTitle: String
        public var uri: String
        public var content: String
        public var startLine: Int?
        public var endLine: Int?
        @FallbackDecoding<ReferenceKindFallback>
        public var kind: Kind

        public init(
            title: String,
            subTitle: String,
            content: String,
            uri: String,
            startLine: Int?,
            endLine: Int?,
            kind: Kind
        ) {
            self.title = title
            self.subTitle = subTitle
            self.content = content
            self.uri = uri
            self.startLine = startLine
            self.endLine = endLine
            self.kind = kind
        }
    }

    /// The role of a message.
    @FallbackDecoding<ChatMessageRoleFallback>
    public var role: Role

    /// The content of the message, either the chat message, or a result of a function call.
    public var content: String

    /// The summary of a message that is used for display.
    public var summary: String?

    /// The id of the message.
    public var id: ID
    
    /// The turn id of the message.
    public var turnId: ID?
    
    /// Rate assistant message
    public var rating: ConversationRating = .unrated

    /// The references of this message.
    @FallbackDecoding<EmptyArray<Reference>>
    public var references: [Reference]

    public init(
        id: String = UUID().uuidString,
        role: Role,
        turnId: String? = nil,
        content: String,
        summary: String? = nil,
        references: [Reference] = []
    ) {
        self.role = role
        self.content = content
        self.summary = summary
        self.id = id
        self.turnId = turnId
        self.references = references
    }
}

public struct ReferenceKindFallback: FallbackValueProvider {
    public static var defaultValue: ChatMessage.Reference.Kind { .other }
}

public struct ChatMessageRoleFallback: FallbackValueProvider {
    public static var defaultValue: ChatMessage.Role { .user }
}

