import CopilotForXcodeKit
import Foundation
import Preferences
import ConversationServiceProvider

public typealias CopilotForXcodeCapability = CopilotForXcodeExtensionCapability & CopilotForXcodeChatCapability

public protocol CopilotForXcodeChatCapability {
    /// Not implemented yet.
    var conversationService: ConversationServiceType? { get }
}

public protocol BuiltinExtension: CopilotForXcodeCapability {
    /// An id that let the extension manager determine whether the extension is in use.
    var suggestionServiceId: BuiltInSuggestionFeatureProvider { get }

    /// It's usually called when the app is about to quit,
    /// you should clean up all the resources here.
    func terminate()
}

