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
                text: wrapBinding($gitHubCopilotProxyUrl)
            )
            SettingsTextField(
                title: "Proxy username",
                prompt: "username",
                text: wrapBinding($gitHubCopilotProxyUsername)
            )
            SettingsSecureField(
                title: "Proxy password",
                prompt: "password",
                text: wrapBinding($gitHubCopilotProxyPassword)
            )
            SettingsToggle(
                title: "Proxy strict SSL",
                isOn: wrapBinding($gitHubCopilotUseStrictSSL)
            )
        }
    }

    private func wrapBinding<T>(_ b: Binding<T>) -> Binding<T> {
        DebouncedBinding(b, handler: refreshConfiguration).binding
    }

    func refreshConfiguration(_: Any) {
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
