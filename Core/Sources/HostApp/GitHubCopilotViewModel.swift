import Foundation
import GitHubCopilotService
import ComposableArchitecture
import Status
import SwiftUI

struct SignInResponse {
    let userCode: String
    let verificationURL: URL
}

@MainActor
class GitHubCopilotViewModel: ObservableObject {
    @Dependency(\.toast) var toast
    @Dependency(\.openURL) var openURL
    
    @AppStorage("username") var username: String = ""
    
    @Published var isRunningAction: Bool = false
    @Published var status: GitHubCopilotAccountStatus?
    @Published var version: String?
    @Published var userCode: String?
    @Published var isSignInAlertPresented = false
    @Published var signInResponse: SignInResponse?
    @Published var waitingForSignIn = false
    
    static var copilotAuthService: GitHubCopilotAuthServiceType?
    
    func getGitHubCopilotAuthService() throws -> GitHubCopilotAuthServiceType {
        if let service = Self.copilotAuthService { return service }
        let service = try GitHubCopilotService()
        Self.copilotAuthService = service
        return service
    }
    
    func signIn() {
        Task {
            isRunningAction = true
            defer { isRunningAction = false }
            do {
                let service = try getGitHubCopilotAuthService()
                let (uri, userCode) = try await service.signInInitiate()
                guard let url = URL(string: uri) else {
                    toast("Verification URI is incorrect.", .error)
                    return
                }
                self.signInResponse = .init(userCode: userCode, verificationURL: url)
                self.isSignInAlertPresented = true
            } catch {
                toast(error.localizedDescription, .error)
            }
        }
    }
    
    func checkStatus() {
        Task {
            isRunningAction = true
            defer { isRunningAction = false }
            do {
                let service = try getGitHubCopilotAuthService()
                status = try await service.checkStatus()
                version = try await service.version()
                isRunningAction = false
                
                if status != .ok, status != .notSignedIn {
                    toast(
                        "GitHub Copilot status is not \"ok\". Please check if you have a valid GitHub Copilot subscription.",
                        .error
                    )
                }
            } catch {
                toast(error.localizedDescription, .error)
            }
        }
    }
    
    func signOut() {
        Task {
            isRunningAction = true
            defer { isRunningAction = false }
            do {
                let service = try getGitHubCopilotAuthService()
                status = try await service.signOut()
                broadcastStatusChange()
            } catch {
                toast(error.localizedDescription, .error)
            }
        }
    }
    
    func cancelWaiting() {
        waitingForSignIn = false
    }
    
    func copyAndOpen() {
        waitingForSignIn = true
        guard let signInResponse else {
            toast("Missing sign in details.", .error)
            return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(signInResponse.userCode, forType: NSPasteboard.PasteboardType.string)
        toast("Sign-in code \(signInResponse.userCode) copied", .info)
        Task {
            await openURL(signInResponse.verificationURL)
            waitForSignIn()
        }
    }
    
    func waitForSignIn() {
        Task {
            do {
                guard waitingForSignIn else { return }
                guard let signInResponse else {
                    waitingForSignIn = false
                    return
                }
                let service = try getGitHubCopilotAuthService()
                let (username, status) = try await service.signInConfirm(userCode: signInResponse.userCode)
                waitingForSignIn = false
                self.username = username
                self.status = status
                broadcastStatusChange()
            } catch let error as GitHubCopilotError {
                if case .languageServerError(.timeout) = error {
                    // TODO figure out how to extend the default timeout on a Chime LSP request
                    // Until then, reissue request
                    waitForSignIn()
                    return
                }
                throw error
            } catch {
                toast(error.localizedDescription, .error)
            }
        }
    }

    func broadcastStatusChange() {
        DistributedNotificationCenter.default().post(
            name: .authStatusDidChange,
            object: nil
        )
    }
}
