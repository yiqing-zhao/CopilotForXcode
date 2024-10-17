import SwiftUI

struct EnterpriseSection: View {
    @AppStorage(\.gitHubCopilotEnterpriseURI) var gitHubCopilotEnterpriseURI

    var body: some View {
        SettingsSection(title: "Enterprise") {
            SettingsTextField(
                title: "Auth provider URL",
                prompt: "Leave it blank if none is available.",
                text: $gitHubCopilotEnterpriseURI
            )
        }
    }
}

#Preview {
    EnterpriseSection()
}
