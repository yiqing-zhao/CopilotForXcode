import Preferences
import SharedUIComponents
import SwiftUI
import XPCShared
import Toast
import Client

struct SuggesionSettingProxyView: View {
    class Settings: ObservableObject {
        @AppStorage("username") var username: String = ""
        @AppStorage(\.gitHubCopilotProxyUrl) var gitHubCopilotProxyUrl
        @AppStorage(\.gitHubCopilotProxyUsername) var gitHubCopilotProxyUsername
        @AppStorage(\.gitHubCopilotProxyPassword) var gitHubCopilotProxyPassword
        @AppStorage(\.gitHubCopilotUseStrictSSL) var gitHubCopilotUseStrictSSL
        @AppStorage(\.gitHubCopilotEnterpriseURI) var gitHubCopilotEnterpriseURI
    }
    
    @StateObject var settings = Settings()
    @Environment(\.toast) var toast
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(StringConstants.enterprise)
                .bold()
                .padding(.leading, 8)
            
            Form {
                TextField(
                    text: $settings.gitHubCopilotEnterpriseURI,
                    prompt: Text(StringConstants.leaveBlankPrompt)
                ) {
                    Text(StringConstants.authProviderURL)
                }
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.trailing)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            .padding(.bottom, 16)
            
            Text(StringConstants.proxy)
                .bold()
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                Form {
                    TextField(
                        text: $settings.gitHubCopilotProxyUrl,
                        prompt: Text(StringConstants.proxyURLPrompt)
                    ) {
                        Text(StringConstants.proxyURL)
                    }
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                Divider()
                
                Form {
                    TextField(text: $settings.gitHubCopilotProxyUsername, prompt: Text(StringConstants.proxyUsernamePrompt)) {
                        Text(StringConstants.proxyUsername)
                    }
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                Divider()
                
                Form {
                    SecureField(text: $settings.gitHubCopilotProxyPassword, prompt: Text(StringConstants.proxyPasswordPrompt)) {
                        Text(StringConstants.proxyPassword)
                    }
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                Divider()
                
                HStack {
                    Text(StringConstants.proxyStrictSSL)
                    Spacer()
                    Toggle("", isOn: $settings.gitHubCopilotUseStrictSSL)
                        .toggleStyle(.switch)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            .padding(.bottom, 8)
            
            HStack {
                Spacer()
                Button(StringConstants.refreshConfigurations) {
                    refreshConfiguration()
                }
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .padding(16)
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

#Preview {
    SuggesionSettingProxyView()
}
