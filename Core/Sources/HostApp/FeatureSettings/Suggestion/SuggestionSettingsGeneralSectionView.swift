import Client
import Preferences
import SharedUIComponents
import SwiftUI
import XPCShared

struct SuggestionSettingsGeneralSectionView: View {
    final class Settings: ObservableObject {
        @AppStorage(\.realtimeSuggestionToggle)
        var realtimeSuggestionToggle
        @AppStorage(\.suggestionFeatureEnabledProjectList)
        var suggestionFeatureEnabledProjectList
        @AppStorage(\.acceptSuggestionWithTab)
        var acceptSuggestionWithTab
    }

    @StateObject var settings = Settings()
    @State var isSuggestionFeatureDisabledLanguageListViewOpen = false

    var body: some View {
        Form {
            Toggle(isOn: $settings.realtimeSuggestionToggle) {
                Text("Request suggestions in real-time")
            }

            Toggle(isOn: $settings.acceptSuggestionWithTab) {
                HStack {
                    Text("Accept suggestions with Tab")
                }
            }

            HStack {
                Button("Disabled language list") {
                    isSuggestionFeatureDisabledLanguageListViewOpen = true
                }
            }.sheet(isPresented: $isSuggestionFeatureDisabledLanguageListViewOpen) {
                SuggestionFeatureDisabledLanguageListView(
                    isOpen: $isSuggestionFeatureDisabledLanguageListViewOpen
                )
            }
        }
    }
}

#Preview {
    SuggestionSettingsGeneralSectionView()
        .padding()
}

