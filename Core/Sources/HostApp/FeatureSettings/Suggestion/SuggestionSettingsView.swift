import Client
import Preferences
import SharedUIComponents
import SwiftUI
import XPCShared

struct SuggestionSettingsView: View {
    var body: some View {
        ScrollView {
            SuggestionSettingsGeneralSectionView()
            SuggesionSettingProxyView()
            LoggingSettingsView()
        }.padding()
    }
}

struct SuggestionSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionSettingsView()
            .frame(width: 600, height: 500)
    }
}

