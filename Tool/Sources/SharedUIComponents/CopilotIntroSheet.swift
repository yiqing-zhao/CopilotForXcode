import SwiftUI
import AppKit

struct CopilotIntroItem: View {
    let heading: String
    let text: String
    let image: Image

    public init(imageName: String, heading: String, text: String) {
        self.init(imageObject: Image(imageName), heading: heading, text: text)
    }

    public init(systemImage: String, heading: String, text: String) {
        self.init(imageObject: Image(systemName: systemImage), heading: heading, text: text)
    }

    public init(imageObject: Image, heading: String, text: String) {
        self.heading = heading
        self.text = text
        self.image = imageObject
    }

    var body: some View {
        HStack(spacing: 16) {
            image
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color(red: 0.0353, green: 0.4118, blue: 0.8549))
                .scaledToFit()
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 5) {
                Text(heading)
                    .font(.system(size: 11, weight: .bold))
                Text(text)
                    .font(.system(size: 11))
                    .lineSpacing(3)
            }
        }
    }
}

public struct CopilotIntroSheet<Content: View>: View {
    let content: Content
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    @AppStorage(\.hideIntro) var hideIntro
    @AppStorage(\.introLastShownVersion) var introLastShownVersion
    @State var isPresented = false

    public var body: some View {
        content.sheet(isPresented: $isPresented) {
            VStack {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .padding(.bottom, 24)
                Text("Welcome to Copilot for Xcode!")
                    .font(.title)
                    .padding(.bottom, 45)

                VStack(alignment: .leading, spacing: 25) {
                    CopilotIntroItem(
                        imageName: "CopilotLogo",
                        heading: "In-line Code Suggestions",
                        text: "Copilot's code suggestions and text completion now available in Xcode. Just press Tab ⇥ to accept a suggestion."
                    )

                    CopilotIntroItem(
                        systemImage: "option",
                        heading: "Full Suggestion",
                        text: "Press Option ⌥ key to display the full suggestion. Only the first line of suggestions are shown inline."
                    )

                    CopilotIntroItem(
                        imageName: "GitHubMark",
                        heading: "GitHub Context",
                        text: "Copilot utilizes GitHub and project context to deliver smarter completions and personalized code suggestions relevant to your unique codebase."
                    )
                }

                Spacer()

                VStack(spacing: 8) {
                    Button(action: { isPresented = false }) {
                        Text("Continue")
                            .padding(.horizontal, 80)
                            .padding(.vertical, 6)
                    }
                        .buttonStyle(.borderedProminent)

                    Toggle("Don't show again", isOn: $hideIntro)
                        .toggleStyle(.checkbox)
                }
            }
            .padding(EdgeInsets(top: 50, leading: 50, bottom: 16, trailing: 50))
            .frame(width: 560, height: 528)
        }
        .task {
            let neverShown = introLastShownVersion.isEmpty
            isPresented = neverShown || !hideIntro
            if isPresented {
                hideIntro = neverShown ? true : hideIntro // default to hidden on first time
                introLastShownVersion = appVersion
            }
        }
    }
}

public extension View {
    func copilotIntroSheet() -> some View {
        CopilotIntroSheet(content: self)
    }
}
