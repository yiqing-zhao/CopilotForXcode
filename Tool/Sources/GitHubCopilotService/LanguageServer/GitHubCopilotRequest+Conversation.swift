import CopilotForXcodeKit
import Foundation
import LanguageServerProtocol
import SuggestionBasic
import ConversationServiceProvider

enum ConversationSource: String, Codable {
    case panel, inline
}

public struct Doc: Codable {
    var position: Position?
    var uri: String
}

struct Reference: Codable {
    let uri: String
    let position: Position?
    let visibleRange: SuggestionBasic.CursorRange?
    let selection: SuggestionBasic.CursorRange?
    let openedAt: String?
    let activeAt: String?
}

struct ConversationCreateParams: Codable {
    var workDoneToken: String
    var turns: [ConversationTurn]
    var capabilities: Capabilities
    var doc: Doc?
    var references: [Reference]?
    var computeSuggestions: Bool?
    var source: ConversationSource?
    var workspaceFolder: String?

    struct Capabilities: Codable {
        var skills: [String]
        var allSkills: Bool?
    }
}

public struct ConversationProgress: Codable {
    public struct FollowUp: Codable {
        public var message: String
        public var id: String
        public var type: String
    }

    public let kind: String
    public let conversationId: String
    public let turnId: String
    public let reply: String?
    public let suggestedTitle: String?

    init(kind: String, conversationId: String, turnId: String, reply: String = "", suggestedTitle: String? = nil) {
        self.kind = kind
        self.conversationId = conversationId
        self.turnId = turnId
        self.reply = reply
        self.suggestedTitle = suggestedTitle
    }
}

// MARK: Conversation rating

struct ConversationRatingParams: Codable {
    var turnId: String
    var rating: ConversationRating
    var doc: Doc?
    var source: ConversationSource?
}

// MARK: Conversation turn

struct ConversationTurn: Codable {
    var request: String
    var response: String?
    var turnId: String?
}

struct TurnCreateParams: Codable {
    var workDoneToken: String
    var conversationId: String
    var message: String
    var doc: Doc?
}

// MARK: Copy

struct CopyCodeParams: Codable {
    var turnId: String
    var codeBlockIndex: Int
    var copyType: CopyKind
    var copiedCharacters: Int
    var totalCharacters: Int
    var copiedText: String
    var doc: Doc?
    var source: ConversationSource?
}
