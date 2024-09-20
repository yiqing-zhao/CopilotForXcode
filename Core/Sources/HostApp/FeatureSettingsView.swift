import SwiftUI

struct FeatureSettingsView: View {
    var body: some View {
        SuggestionSettingsView()
            .sidebarItem(
                tag: 0,
                title: "Suggestion",
                subtitle: "Generate suggestions for your code",
                image: "lightbulb"
            )
    }
}

struct FeatureSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        FeatureSettingsView()
            .frame(width: 800)
    }
}

