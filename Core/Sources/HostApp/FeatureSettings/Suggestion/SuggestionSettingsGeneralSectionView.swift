import Client
import Preferences
import SharedUIComponents
import SwiftUI
import XPCShared

struct SuggestionSettingsGeneralSectionView: View {
    final class Settings: ObservableObject {
        @AppStorage(\.realtimeSuggestionToggle) var realtimeSuggestionToggle
        @AppStorage(\.suggestionFeatureEnabledProjectList) var suggestionFeatureEnabledProjectList
        @AppStorage(\.acceptSuggestionWithTab) var acceptSuggestionWithTab
    }

    @StateObject var settings = Settings()
    @State var isSuggestionFeatureDisabledLanguageListViewOpen = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(StringConstants.suggestionSettings)
                .bold()
                .padding(.leading, 8)
            
            VStack(spacing: .zero) {
                HStack(alignment: .center) {
                    Text(StringConstants.requestSuggestionsInRealTime)
                        .padding(.horizontal, 8)
                    Spacer()
                    Toggle(isOn: $settings.realtimeSuggestionToggle) {
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 8)

                Divider()

                HStack(alignment: .center) {
                    Text(StringConstants.acceptSuggestionsWithTab)
                        .padding(.horizontal, 8)
                    Spacer()
                    Toggle(isOn: $settings.acceptSuggestionWithTab) {
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 8)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            .padding(.bottom, 8)

            HStack {
                Spacer()
                Button(StringConstants.disabledLanguageList) {
                    isSuggestionFeatureDisabledLanguageListViewOpen = true
                }
            }
            .padding(.horizontal)
            .sheet(isPresented: $isSuggestionFeatureDisabledLanguageListViewOpen) {
                SuggestionFeatureDisabledLanguageListView(isOpen: $isSuggestionFeatureDisabledLanguageListViewOpen)
            }
            Spacer()
        }
        .padding(16)
    }
}

#Preview {
    SuggestionSettingsGeneralSectionView()
        .padding()
}

