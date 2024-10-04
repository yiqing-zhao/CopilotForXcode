import Client
import GitHubCopilotService
import ComposableArchitecture
import KeyboardShortcuts
import LaunchAgentManager
import Preferences
import SharedUIComponents
import SwiftUI
import XPCShared
import Cocoa

struct SignInResponse {
    let userCode: String
    let verificationURL: URL
}

struct GeneralView: View {
    let store: StoreOf<General>
    @StateObject private var viewModel = GitHubCopilotViewModel()
  
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AppInfoView(viewModel: viewModel, store: store)
                GeneralSettingsView(store: store)
                CopilotConnectionView(viewModel: viewModel, store: store)
                    .padding(.bottom, 20)
                Divider()
                Spacer().frame(height: 40)
                rightsView
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            store.send(.appear)
        }
    }
    
    var rightsView: some View {
        Text(StringConstants.rightsReserved)
            .font(.caption2)
            .foregroundColor(.secondary.opacity(0.5))
    }
}

struct AppInfoView: View {
    class Settings: ObservableObject {
        @AppStorage(\.installPrereleases)
        var installPrereleases
    }
    
    static var copilotAuthService: GitHubCopilotAuthServiceType?
   
    @Environment(\.updateChecker) var updateChecker
    @Environment(\.toast) var toast
    
    @StateObject var settings = Settings()
    @StateObject var viewModel: GitHubCopilotViewModel
    
    @State var automaticallyCheckForUpdate: Bool?
    @State var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    let store: StoreOf<General>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 16) {
                Image("copilotIcon")
                    .resizable()
                    .frame(width: 110, height: 110)
                VStack(alignment: .leading) {
                    HStack {
                        Text(Bundle.main.object(forInfoDictionaryKey: "HOST_APP_NAME") as? String ?? StringConstants.appName)
                            .font(.title)
                        Text("(\(appVersion ?? ""))")
                            .font(.title)
                    }
                    Text("\(StringConstants.languageServerVersion) \(viewModel.version ?? StringConstants.loading)")
                    Button(action: {
                        updateChecker.checkForUpdates()
                    }) {
                        HStack(spacing: 2) {
                            Text(StringConstants.checkForUpdates)
                        }
                    }
                    HStack {
                        Toggle(isOn: .init(
                            get: { automaticallyCheckForUpdate ?? updateChecker.automaticallyChecksForUpdates },
                            set: {
                                updateChecker.automaticallyChecksForUpdates = $0
                                automaticallyCheckForUpdate = $0
                            }
                        )) {
                            Text(StringConstants.automaticallyCheckForUpdates)
                        }
                        
                        Toggle(isOn: $settings.installPrereleases) {
                            Text(StringConstants.installPreReleases)
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 2)
        }
        .padding()
        .onAppear {
            if isPreview { return }
            viewModel.checkStatus()
        }
    }
}

struct GeneralSettingsView: View {
    
    class Settings: ObservableObject {
        @AppStorage(\.quitXPCServiceOnXcodeAndAppQuit)
        var quitXPCServiceOnXcodeAndAppQuit

    }
    
    @StateObject var settings = Settings()
    @Environment(\.updateChecker) var updateChecker
    @AppStorage(\.realtimeSuggestionToggle) var isCopilotEnabled: Bool
    @State private var shouldPresentInstructionSheet = false
    @State private var shouldPresentTurnoffSheet = false
    
    let store: StoreOf<General>
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(StringConstants.general)
                .bold()
                .padding(.leading, 8)
            VStack(spacing: .zero) {
                HStack(alignment: .center) {
                    Text(StringConstants.quitCopilot)
                        .padding(.horizontal, 8)
                    Spacer()
                    Toggle(isOn: $settings.quitXPCServiceOnXcodeAndAppQuit) {
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 8)
                
                Divider()
                Link(destination: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!) {
                    HStack {
                        VStack(alignment: .leading) {
                            let grantedStatus: String = {
                                guard let granted = store.isAccessibilityPermissionGranted else { return StringConstants.loading }
                                return granted ? "Granted" : "Not Granted"
                            }()
                            Text(StringConstants.accessibilityPermissions)
                                .font(.body)
                            Text("\(StringConstants.status) \(grantedStatus) ⓘ")
                                .font(.footnote)
                        }
                        Spacer()
                        
                        Image(systemName: "control")
                            .rotationEffect(.degrees(90))
                    }
                }
                .foregroundStyle(.primary)
                .padding(8)
                
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        let grantedStatus: String = {
                            guard let granted = store.isAccessibilityPermissionGranted else { return StringConstants.loading }
                            return granted ? "Granted" : "Not Granted"
                        }()
                        Text(StringConstants.extensionPermissions)
                            .font(.body)
                        Text("\(StringConstants.status) \(grantedStatus) ⓘ")
                            .font(.footnote)
                            .onTapGesture {
                                shouldPresentInstructionSheet = true
                            }
                    }
                    Spacer()
                    Link(destination: URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!) {
                        Image(systemName: "control")
                            .rotationEffect(.degrees(90))
                    }
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            HStack(alignment: .center) {
                Spacer()
                Button(action: {
                    if isCopilotEnabled {
                        shouldPresentTurnoffSheet = true
                    } else {
                        isCopilotEnabled = true
                    }
                }) {
                    Text(isCopilotEnabled ? StringConstants.turnOffCopilot : StringConstants.turnOnCopilot)
                        .padding(.horizontal, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $shouldPresentInstructionSheet) {
        } content: {
            InstructionSheet {
                shouldPresentInstructionSheet = false
            }
        }
        .alert(isPresented: $shouldPresentTurnoffSheet) {
            Alert(
                title: Text(StringConstants.turnOffAlertTitle),
                message: Text(StringConstants.turnOffAlertMessage),
                primaryButton: .default(Text("Turn off").foregroundColor(.blue)){
                    isCopilotEnabled = false
                    shouldPresentTurnoffSheet = false
                },
                secondaryButton: .cancel(Text(StringConstants.cancel)) {
                    shouldPresentTurnoffSheet = false
                }
            )
        }
    }
}


struct CopilotConnectionView: View {
    @AppStorage("username") var username: String = ""
    @Environment(\.toast) var toast
    @StateObject var viewModel = GitHubCopilotViewModel()

    @State var waitingForSignIn = false
    let store: StoreOf<General>
    
    var body: some View {
        WithPerceptionTracking {
            VStack {
                connection
                    .padding(.bottom, 20)
                copilotResources
            }
        }
    }

    var connection: some View {
        VStack(alignment: .leading) {
            Text(StringConstants.copilotResources)
                .bold()
                .padding(.leading, 8)
            VStack(spacing: .zero) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(StringConstants.githubAccountStatus)
                            .font(.body)
                        Text("\(StringConstants.githubConnection) \(viewModel.status?.description ?? StringConstants.loading)")
                            .font(.footnote)
                    }
                    Spacer()
                    Button(StringConstants.refreshConnection) {
                        viewModel.checkStatus()
                    }
                    if waitingForSignIn {
                        Button(StringConstants.cancel) {
                            viewModel.cancelWaiting()
                        }
                    } else if viewModel.status == .notSignedIn {
                        Button(StringConstants.loginToGitHub) {
                            viewModel.signIn()
                        }
                        .alert(
                            viewModel.signInResponse?.userCode ?? "",
                            isPresented: $viewModel.isSignInAlertPresented,
                            presenting: viewModel.signInResponse) { _ in
                                Button(StringConstants.cancel, role: .cancel, action: {})
                                Button("Copy Code and Open", action: viewModel.copyAndOpen)
                            } message: { response in
                                Text("""
                                       Please enter the above code in the \
                                       GitHub website to authorize your \
                                       GitHub account with Copilot for Xcode.
                                       
                                       \(response?.verificationURL.absoluteString ?? "")
                                       """)
                            }
                    }
                    if viewModel.status == .ok || viewModel.status == .alreadySignedIn ||
                        viewModel.status == .notAuthorized
                    {
                        Button(StringConstants.logoutFromGitHub) { viewModel.signOut()
                            viewModel.isSignInAlertPresented = false
                        }
                    }
                    if viewModel.isRunningAction || waitingForSignIn {
                        ActivityIndicatorView()
                    }
                }
                .opacity(viewModel.isRunningAction ? 0.8 : 1)
                .disabled(viewModel.isRunningAction)
                .padding(8)
                
                Divider()
                Link(destination: URL(string: "https://github.com/settings/copilot")!) {
                    HStack {
                        Text(StringConstants.githubCopilotSettings)
                            .font(.body)
                        Spacer()
                        
                        Image(systemName: "control")
                            .rotationEffect(.degrees(90))
                    }
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
        }
        .padding(.horizontal, 20)
        .onAppear {
            store.send(.reloadStatus)
            viewModel.checkStatus()
        }
    }

    var copilotResources: some View {
        VStack(alignment: .leading) {
            Text(StringConstants.copilotResources)
                .bold()
                .padding(.leading, 8)
            
            VStack(spacing: .zero) {
                let docURL = URL(string: (Bundle.main.object(forInfoDictionaryKey: "COPILOT_DOCS_URL") as? String) ?? "https://docs.github.com/en/copilot")!
                Link(destination: docURL) {
                    HStack {
                        Text(StringConstants.copilotDocumentation)
                            .font(.body)
                        Spacer()
                        Image(systemName: "control")
                            .rotationEffect(.degrees(90))
                    }
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)

                Divider()

                let forumURL = URL(string: (Bundle.main.object(forInfoDictionaryKey: "COPILOT_FORUM_URL") as? String) ?? "https://github.com/orgs/community/discussions/categories/copilot")!
                Link(destination: forumURL) {
                    HStack {
                        Text(StringConstants.copilotFeedbackForum)
                            .font(.body)
                        Spacer()
                        Image(systemName: "control")
                            .rotationEffect(.degrees(90))
                    }
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
        }
        .padding(.horizontal, 20)
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
    
struct GeneralView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralView(store: .init(initialState: .init(), reducer: { General() }))
            .frame(height: 800)
    }
}

