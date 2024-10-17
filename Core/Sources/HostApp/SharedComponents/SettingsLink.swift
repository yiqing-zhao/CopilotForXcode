import SwiftUI

struct SettingsLink: View {
    let url: URL
    let title: String
    let subtitle: String?

    init(_ url: URL, title: String, subtitle: String? = nil) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
    }

    init(url: String, title: String, subtitle: String? = nil) {
        self.init(URL(string: url)!, title: title, subtitle: subtitle)
    }

    var body: some View {
        Link(destination: url) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.footnote)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
        .foregroundStyle(.primary)
        .padding(10)
    }
}

#Preview {
    SettingsLink(
        url: "https://example.com",
        title: "Example",
        subtitle: "This is an example"
    )
}
