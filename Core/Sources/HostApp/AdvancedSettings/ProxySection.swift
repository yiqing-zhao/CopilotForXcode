import Client
import SwiftUI
import Toast

struct ProxySection: View {
    @AppStorage(\.gitHubCopilotProxyUrl) var gitHubCopilotProxyUrl
    @AppStorage(\.gitHubCopilotProxyUsername) var gitHubCopilotProxyUsername
    @AppStorage(\.gitHubCopilotProxyPassword) var gitHubCopilotProxyPassword
    @AppStorage(\.gitHubCopilotUseStrictSSL) var gitHubCopilotUseStrictSSL

    @Environment(\.toast) var toast

    var body: some View {
        SettingsSection(title: "Proxy") {
            SettingsTextField(
                title: "Proxy URL",
                prompt: "http://host:port",
                text: $gitHubCopilotProxyUrl
            )
            SettingsTextField(
                title: "Proxy username",
                prompt: "username",
                text: $gitHubCopilotProxyUsername
            )
            SettingsSecureField(
                title: "Proxy password",
                prompt: "password",
                text: $gitHubCopilotProxyPassword
            )
            SettingsToggle(
                title: "Proxy strict SSL",
                isOn: $gitHubCopilotUseStrictSSL
            )
        } footer: {
            HStack {
                Spacer()
                Button("Refresh configurations") {
                    refreshConfiguration()
                }
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

#Preview {
    ProxySection()
}
