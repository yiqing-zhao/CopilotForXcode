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
        
        init() {}
    }
    
    @StateObject var settings = Settings()
    @Environment(\.toast) var toast
    
    var body: some View {
        VStack(alignment: .leading) {
            SettingsDivider("Enterprise")
            
            Form {
                TextField(
                    text: $settings.gitHubCopilotEnterpriseURI,
                    prompt: Text("Leave it blank if none is available.")
                ) {
                    Text("Auth provider URL")
                }
            }
            
            SettingsDivider("Proxy")
            
            Form {
                TextField(
                    text: $settings.gitHubCopilotProxyUrl,
                    prompt: Text("http://host:port")
                ) {
                    Text("Proxy URL")
                }
                TextField(text: $settings.gitHubCopilotProxyUsername) {
                    Text("Proxy username")
                }
                SecureField(text: $settings.gitHubCopilotProxyPassword) {
                    Text("Proxy password")
                }
                Toggle("Proxy strict SSL", isOn: $settings.gitHubCopilotUseStrictSSL)
                
                Button("Refresh configurations") {
                    refreshConfiguration()
                }.padding(.top, 6)
            }
        }
        .textFieldStyle(.roundedBorder)
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
