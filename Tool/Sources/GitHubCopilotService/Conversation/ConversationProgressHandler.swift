import Combine
import Foundation
import JSONRPC
import LanguageServerProtocol

public enum ProgressKind: String {
    case begin, report, end
}

public protocol ConversationProgressHandler {
    var onBegin: PassthroughSubject<(String, ConversationProgress), Never> { get }
    var onProgress: PassthroughSubject<(String, ConversationProgress), Never> { get }
    var onEnd: PassthroughSubject<(String, ConversationProgress), Never> { get }
    func handleConversationProgress(_ progressParams: ProgressParams)
}

public final class ConversationProgressHandlerImpl: ConversationProgressHandler {
    public static let shared = ConversationProgressHandlerImpl()

    public var onBegin = PassthroughSubject<(String, ConversationProgress), Never>()
    public var onProgress = PassthroughSubject<(String, ConversationProgress), Never>()
    public var onEnd = PassthroughSubject<(String, ConversationProgress), Never>()

    private var cancellables = Set<AnyCancellable>()

    public func handleConversationProgress(_ progressParams: ProgressParams) {
        guard let token = getValueAsString(from: progressParams.token),
              let data = try? JSONEncoder().encode(progressParams.value),
              let progress = try? JSONDecoder().decode(ConversationProgress.self, from: data) else {
            print("Error encountered while parsing conversation progress params")
            return
        }

        if let kind = ProgressKind(rawValue: progress.kind) {
            switch kind {
            case .begin:
                onBegin.send((token, progress))
            case .report:
                onProgress.send((token, progress))
            case .end:
                onEnd.send((token, progress))
            }
        }
    }

    private func getValueAsString(from token: ProgressToken) -> String? {
        switch token {
        case .optionA(let intValue):
            return String(intValue)
        case .optionB(let stringValue):
            return stringValue
        }
    }
}
