import AppKit
import Logger
import Preferences
import SwiftUI

struct LoggingSettingsView: View {
    @AppStorage(\.verboseLoggingEnabled) var verboseLoggingEnabled: Bool
    @State private var shouldPresentRestartAlert = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Logging")
                .bold()
                .padding(.leading, 8)
            VStack(spacing: .zero) {
                HStack(alignment: .center) {
                    Text("Verbose Logging")
                        .padding(.horizontal, 8)
                    Spacer()
                    Toggle(isOn: $verboseLoggingEnabled) {
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 8)
                .onChange(of: verboseLoggingEnabled) { _ in
                    shouldPresentRestartAlert = true
                }

                Divider()

                HStack {
                    Text("Open Copilot Log Folder")
                        .font(.body)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .onTapGesture {
                    NSWorkspace.shared.open(URL(fileURLWithPath: FileLoggingLocation.path.string, isDirectory: true))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .alert(isPresented: $shouldPresentRestartAlert) {
            Alert(
                title: Text("Quit And Restart Xcode"),
                message: Text(
                    """
                    Logging level changes will take effect the next time Copilot \
                    for Xcode is started. To update logging now, please quit \
                    Copilot for Xcode and restart Xcode.
                    """
                ),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
