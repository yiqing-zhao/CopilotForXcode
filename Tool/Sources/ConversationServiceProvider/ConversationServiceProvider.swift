import CopilotForXcodeKit

public protocol ConversationServiceType {
    func createConversation(_ request: ConversationRequest, workspace: WorkspaceInfo) async throws
    func createTurn(with conversationId: String, request: ConversationRequest, workspace: WorkspaceInfo) async throws
    func cancelProgress(_ workDoneToken: String, workspace: WorkspaceInfo) async throws
    func rateConversation(turnId: String, rating: ConversationRating, workspace: WorkspaceInfo) async throws
    func copyCode(request: CopyCodeRequest, workspace: WorkspaceInfo) async throws
}

public protocol ConversationServiceProvider {
    func createConversation(_ request: ConversationRequest) async throws
    func createTurn(with conversationId: String, request: ConversationRequest) async throws
    func stopReceivingMessage(_ workDoneToken: String) async throws
    func rateConversation(turnId: String, rating: ConversationRating) async throws
    func copyCode(_ request: CopyCodeRequest) async throws
}

public struct ConversationRequest {
    public var workDoneToken: String
    public var content: String
    public var workspaceFolder: String
    public var skills: [String]

    public init(
        workDoneToken: String,
        content: String,
        workspaceFolder: String,
        skills: [String]
    ) {
        self.workDoneToken = workDoneToken
        self.content = content
        self.workspaceFolder = workspaceFolder
        self.skills = skills
    }
}

public struct CopyCodeRequest {
    public var turnId: String
    public var codeBlockIndex: Int
    public var copyType: CopyKind
    public var copiedCharacters: Int
    public var totalCharacters: Int
    public var copiedText: String
    
    init(turnId: String, codeBlockIndex: Int, copyType: CopyKind, copiedCharacters: Int, totalCharacters: Int, copiedText: String) {
        self.turnId = turnId
        self.codeBlockIndex = codeBlockIndex
        self.copyType = copyType
        self.copiedCharacters = copiedCharacters
        self.totalCharacters = totalCharacters
        self.copiedText = copiedText
    }
}

public enum ConversationRating: Int, Codable {
    case unrated = 0
    case helpful = 1
    case unhelpful = -1
}

public enum CopyKind: Int, Codable {
    case keyboard = 1
    case toolbar = 2
}
