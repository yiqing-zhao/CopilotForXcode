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
                .foregroundColor(.blue)
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

struct CopilotIntroContent: View {
    let hideIntro: Binding<Bool>
    let continueAction: () -> Void

    var body: some View {
        VStack {
            let appImage = if let nsImage = NSImage(named: "AppIcon") {
                Image(nsImage: nsImage)
            } else {
                Image(systemName: "app")
            }
            appImage
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .padding(.bottom, 24)
            Text("Welcome to Copilot for Xcode!")
                .font(.title.bold())
                .padding(.bottom, 38)

            VStack(alignment: .leading, spacing: 20) {
                CopilotIntroItem(
                    imageName: "CopilotLogo",
                    heading: "In-line Code Suggestions",
                    text: "Copilot's code suggestions and text completion now available in Xcode. Press Tab ⇥ to accept a suggestion."
                )

                CopilotIntroItem(
                    systemImage: "option",
                    heading: "Full Suggestion",
                    text: "Press Option ⌥ key to display the full suggestion. Only the first line of suggestions are shown inline."
                )

                CopilotIntroItem(
                    imageName: "GitHubMark",
                    heading: "GitHub Context",
                    text: "Copilot utilizes project context to deliver smarter code suggestions relevant to your unique codebase."
                )
            }
            .padding(.bottom, 64)

            VStack(spacing: 8) {
                Button(action: continueAction) {
                    Text("Continue")
                        .padding(.horizontal, 80)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)

                Toggle("Don't show again", isOn: hideIntro)
                    .toggleStyle(.checkbox)
            }
        }
        .padding(.horizontal, 56)
        .padding(.top, 48)
        .padding(.bottom, 16)
        .frame(width: 560)
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
            CopilotIntroContent(hideIntro: $hideIntro) {
                isPresented = false
            }
        }
        .task {
            if hideIntro == false {
                isPresented = true
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


// MARK: - Preview
@available(macOS 14.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    CopilotIntroContent(hideIntro: .constant(false)) { }
}
