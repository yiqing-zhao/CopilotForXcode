import Client
import HostApp
import LaunchAgentManager
import SharedUIComponents
import SwiftUI
import UpdateChecker
import XPCShared

struct VisualEffect: NSViewRepresentable {
  func makeNSView(context: Self.Context) -> NSView { return NSVisualEffectView() }
  func updateNSView(_ nsView: NSView, context: Context) { }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool { true }
}

@main
struct CopilotForXcodeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            TabContainer()
                .frame(minWidth: 800, minHeight: 600)
                .background(VisualEffect().ignoresSafeArea())
                .onAppear {
                    UserDefaults.setupDefaultSettings()
                }
                .environment(\.updateChecker, UpdateChecker(hostBundle: Bundle.main))
                .copilotIntroSheet()
        }
    }
}

var isPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }

