import AppKit
import Client
import GitHubCopilotService
import Preferences
import SharedUIComponents
import SuggestionBasic
import SwiftUI

struct SignInResponse {
    let userCode: String
    let verificationURL: URL
}

struct GitHubCopilotView: View {
    static var copilotAuthService: GitHubCopilotAuthServiceType?

    class Settings: ObservableObject {
        @AppStorage("username") var username: String = ""
        @AppStorage(\.disableGitHubCopilotSettingsAutoRefreshOnAppear)
        var disableGitHubCopilotSettingsAutoRefreshOnAppear
        init() {}
    }

    @Environment(\.openURL) var openURL
    @Environment(\.toast) var toast
    @StateObject var settings = Settings()

    @State var status: GitHubCopilotAccountStatus?
    @State var signInResponse: SignInResponse?
    @State var version: String?
    @State var isRunningAction: Bool = false
    @State var isSignInAlertPresented = false
    @State var xcodeBetaAccessAlert = false
    @State var waitingForSignIn = false

    func getGitHubCopilotAuthService() throws -> GitHubCopilotAuthServiceType {
        if let service = Self.copilotAuthService { return service }
        let service = try GitHubCopilotService()
        Self.copilotAuthService = service
        return service
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Language Server Version: \(version ?? "Loading..")")
                    .alert(isPresented: $xcodeBetaAccessAlert) {
                        Alert(
                            title: Text("Xcode Beta Access Not Granted"),
                            message: Text(
                                "Logged in user does not have access to GitHub Copilot for Xcode"
                            ),
                            dismissButton: .default(Text("Close"))
                        )
                    }

                if waitingForSignIn {
                    Text("Status: Waiting for GitHub authentication")
                } else {
                    Text("""
                        Status: \(status?.description ?? "Loading..")\
                        \(xcodeBetaAccessAlert ? " - Xcode Beta Access Not Granted" : "")
                        """)
                }

                HStack(alignment: .center) {
                    Button("Refresh") {
                        checkStatus()
                    }
                    if waitingForSignIn {
                        Button("Cancel") { cancelWaiting() }
                    } else if status == .notSignedIn {
                        Button("Sign In") { signIn() }
                            .alert(
                                signInResponse?.userCode ?? "",
                                isPresented: $isSignInAlertPresented,
                                presenting: signInResponse) { _ in
                                    Button("Cancel", role: .cancel, action: {})
                                    Button("Copy Code and Open", action: copyAndOpen)
                                } message: { response in
                                    Text("""
                                         Please enter the above code in the \
                                         GitHub website to authorize your \
                                         GitHub account with Copilot for Xcode.
                                         
                                         \(response?.verificationURL.absoluteString ?? "")
                                         """)
                                }
                    }
                    if status == .ok || status == .alreadySignedIn ||
                        status == .notAuthorized
                    {
                        Button("Sign Out") { signOut() }
                    }
                    if isRunningAction || waitingForSignIn {
                        ActivityIndicatorView()
                    }
                }
                .opacity(isRunningAction ? 0.8 : 1)
                .disabled(isRunningAction)
            }
            .padding()

            Spacer()
        }
        .onAppear {
            if isPreview { return }
            if settings.disableGitHubCopilotSettingsAutoRefreshOnAppear { return }
            checkStatus()
        }
        .textFieldStyle(.roundedBorder)
        .onReceive(FeatureFlagNotifierImpl.shared.featureFlagsDidChange) { flags in
            self.xcodeBetaAccessAlert = flags.x != true
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
                isSignInAlertPresented = true
            } catch {
                toast(error.localizedDescription, .error)
            }
        }
    }

    func copyAndOpen() {
        waitingForSignIn = true
        guard let signInResponse else {
            toast("Missing sign in details.", .error)
            return
        }
        // Copy the device code to the clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(signInResponse.userCode, forType: NSPasteboard.PasteboardType.string)
        toast("Sign-in code \(signInResponse.userCode) copied", .info)
        // Open verification URL in default browser
        openURL(signInResponse.verificationURL)
        // Wait for signInConfirm response
        waitForSignIn()
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
                self.settings.username = username
                self.status = status
            } catch let error as GitHubCopilotError {
                if case .languageServerError(.timeout) = error {
                    // TODO figure out how to extend the default timeout on an LSP request
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

    func cancelWaiting() {
        waitingForSignIn = false
    }

    func signOut() {
        Task {
            isRunningAction = true
            defer { isRunningAction = false }
            do {
                let service = try getGitHubCopilotAuthService()
                status = try await service.signOut()
            } catch {
                toast(error.localizedDescription, .error)
            }
        }
    }

    func refreshConfiguration() {
        NotificationCenter.default.post(
            name: .gitHubCopilotShouldRefreshEditorInformation,
            object: nil
        )

        Task {
            let service = try getService()
            do {
                try await service.postNotification(
                    name: Notification.Name
                        .gitHubCopilotShouldRefreshEditorInformation.rawValue
                )
            } catch {
                toast(error.localizedDescription, .error)
            }
        }
    }
}

struct ActivityIndicatorView: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSProgressIndicator {
        let progressIndicator = NSProgressIndicator()
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.startAnimation(nil)
        return progressIndicator
    }

    func updateNSView(_: NSProgressIndicator, context _: Context) {
        // No-op
    }
}

struct CopilotView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 8) {
            GitHubCopilotView(status: .notSignedIn, version: "1.0.0")
            GitHubCopilotView(status: .alreadySignedIn, isRunningAction: true)
            GitHubCopilotView(settings: .init(), status: .alreadySignedIn, xcodeBetaAccessAlert: true)
            GitHubCopilotView(settings: .init(), status: .notSignedIn, waitingForSignIn: true)
        }
        .padding(.all, 8)
        .previewLayout(.sizeThatFits)
    }
}

