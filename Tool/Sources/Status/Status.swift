import AppKit
import Foundation

public enum ExtensionPermissionStatus {
    case unknown
    case succeeded
    case failed
}

@objc public enum ObservedAXStatus: Int {
    case unknown = -1
    case granted = 1
    case notGranted = 0
}

public extension Notification.Name {
    static let serviceStatusDidChange = Notification.Name("com.github.CopilotForXcode.serviceStatusDidChange")
}

public struct StatusResponse {
    public let icon: String
    public let system: Bool // Temporary workaround for status images
    public let message: String?
    public let url: String?
}

public final actor Status {
    public static let shared = Status()

    private var extensionStatus: ExtensionPermissionStatus = .unknown
    private var axStatus: ObservedAXStatus = .unknown

    private init() {}

    public func updateExtensionStatus(_ status: ExtensionPermissionStatus) {
        guard status != extensionStatus else { return }
        extensionStatus = status
        broadcast()
    }

    public func updateAXStatus(_ status: ObservedAXStatus) {
        guard status != axStatus else { return }
        axStatus = status
        broadcast()
    }

    public func getAXStatus() -> ObservedAXStatus {
        // if Xcode is running, return the observed status
        if isXcodeRunning() {
            return axStatus
        } else if AXIsProcessTrusted() {
            // if Xcode is not running but AXIsProcessTrusted() is true, return granted
            return .granted
        } else {
            // otherwise, return the last observed status, which may be unknown
            return axStatus
        }
    }

    private func isXcodeRunning() -> Bool {
        let xcode = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dt.Xcode")
        return !xcode.isEmpty
    }

    public func getStatus() -> StatusResponse {
        if extensionStatus == .failed {
            // TODO differentiate between the permission not being granted and the
            // extension just getting disabled by Xcode.
            return .init(
                icon: "exclamationmark.circle",
                system: true,
                message: """
                  Extension is not enabled. Enable GitHub Copilot under Xcode
                  and then restart Xcode.
                  """,
                url: "x-apple.systempreferences:com.apple.ExtensionsPreferences"
            )
        }

        switch getAXStatus() {
        case .granted:
            return .init(icon: "MenuBarIcon", system: false, message: nil, url: nil)
        case .notGranted:
            return .init(
                icon: "exclamationmark.circle",
                system: true,
                message: """
                  Accessibility permission not granted. \
                  Click to open System Preferences.
                  """,
                url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            )
        case .unknown:
            return .init(
                icon: "exclamationmark.circle",
                system: true,
                message: """
                  Accessibility permission not granted or Copilot restart needed.
                  """,
                url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            )
        }
    }

    private func broadcast() {
        NotificationCenter.default.post(
            name: .serviceStatusDidChange,
            object: nil
        )
        // Can remove DistributedNotificationCenter if the settings UI moves in-process
        DistributedNotificationCenter.default().post(
            name: .serviceStatusDidChange,
            object: nil
        )
    }
}
