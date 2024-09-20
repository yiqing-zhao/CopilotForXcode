//
//  OpenSettingsCommand.swift
//  EditorExtension
//
//  Opens the settings app
//

import Foundation
import XcodeKit

enum GitHubCopilotForXcodeSettingsLaunchError: Error, LocalizedError {
    case appNotFound
    case openFailed(exitCode: Int32)

    var errorDescription: String? {
        switch self {
        case .appNotFound:
            return "\(hostAppName()) settings application not found"
        case let .openFailed(exitCode):
            return "Failed to launch \(hostAppName()) settings (exit code \(exitCode))"
        }
    }
}

class OpenSettingsCommand: NSObject, XCSourceEditorCommand, CommandType {
    var name: String { "Open \(hostAppName()) Settings" }

    func perform(
        with invocation: XCSourceEditorCommandInvocation,
        completionHandler: @escaping (Error?) -> Void
    ) {
        Task {
            if let appPath = locateHostBundleURL(url: Bundle.main.bundleURL)?.absoluteString {
                let task = Process()
                task.launchPath = "/usr/bin/open"
                task.arguments = [appPath]
                task.launch()
                task.waitUntilExit()
                if task.terminationStatus == 0 {
                    completionHandler(nil)
                } else {
                    completionHandler(GitHubCopilotForXcodeSettingsLaunchError.openFailed(exitCode: task.terminationStatus))
                }
            } else {
                completionHandler(GitHubCopilotForXcodeSettingsLaunchError.appNotFound)
            }
        }
    }

    func locateHostBundleURL(url: URL) -> URL? {
        var nextURL = url
        while nextURL.path != "/" {
            nextURL = nextURL.deletingLastPathComponent()
            if nextURL.lastPathComponent.hasSuffix(".app") {
                return nextURL
            }
        }
        let devAppURL = url
            .deletingLastPathComponent()
            .appendingPathComponent("GitHub Copilot for Xcode Dev.app")
        return devAppURL
    }
}

func hostAppName() -> String {
    return Bundle.main.object(forInfoDictionaryKey: "HOST_APP_NAME") as? String
        ?? "GitHub Copilot for Xcode"
}
