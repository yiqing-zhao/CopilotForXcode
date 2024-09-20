import Darwin
import Foundation

final class SystemInfo {
    func binaryPath() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        let path: String
        if identifier == "x86_64" {
            path = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/copilot-language-server").path
        } else if identifier == "arm64" {
            path = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/copilot-language-server-arm64").path
        } else {
            fatalError("Unsupported architecture")
        }

        return path
    }

    func xcodeVersion() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["xcodebuild", "-version"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
        } catch {
            print("Error running xcrun xcodebuild: \(error)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return nil
        }

        let lines = output.split(separator: "\n")
        return lines.first?.split(separator: " ").last.map(String.init)
    }
}
