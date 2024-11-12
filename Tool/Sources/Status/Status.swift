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

public struct CLSStatus: Equatable {
    public enum Status {
        case unknown
        case normal
        case inProgress
        case error
        case warning
        case inactive
    }

    public let status: Status
    public let message: String

    public var isInactiveStatus: Bool {
        status == .inactive && !message.isEmpty
    }

    public var isErrorStatus: Bool {
        (status == .warning || status == .error) && !message.isEmpty
    }
}

public struct AuthStatus: Equatable {
    public enum Status {
        case unknown
        case loggedIn
        case notLoggedIn
    }

    public let status: Status
    public let username: String?
    public let message: String?
}

public extension Notification.Name {
    static let authStatusDidChange = Notification.Name("com.github.CopilotForXcode.authStatusDidChange")
    static let serviceStatusDidChange = Notification.Name("com.github.CopilotForXcode.serviceStatusDidChange")
}

public struct StatusResponse {
    public struct Icon {
        public let name: String

        public init(name: String) {
            self.name = name
        }

        public var nsImage: NSImage? {
            NSImage(named: name)
        }
    }

    public let icon: Icon
    public let inProgress: Bool
    public let message: String?
    public let url: String?
    public let authMessage: String
}

public final actor Status {
    public static let shared = Status()

    private var extensionStatus: ExtensionPermissionStatus = .unknown
    private var axStatus: ObservedAXStatus = .unknown
    private var clsStatus = CLSStatus(status: .unknown, message: "")
    private var authStatus = AuthStatus(status: .unknown, username: nil, message: nil)

    private let okIcon = StatusResponse.Icon(name: "MenuBarIcon")
    private let errorIcon = StatusResponse.Icon(name: "MenuBarWarningIcon")
    private let inactiveIcon = StatusResponse.Icon(name: "MenuBarInactiveIcon")

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

    public func updateCLSStatus(_ status: CLSStatus.Status, message: String) {
        let newStatus = CLSStatus(status: status, message: message)
        guard newStatus != clsStatus else { return }
        clsStatus = newStatus
        broadcast()
    }

    public func updateAuthStatus(_ status: AuthStatus.Status, username: String? = nil, message: String? = nil) {
        let newStatus = AuthStatus(status: status, username: username, message: message)
        guard newStatus != authStatus else { return }
        authStatus = newStatus
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

    public func getAuthStatus() -> AuthStatus.Status {
        return authStatus.status
    }

    public func getStatus() -> StatusResponse {
        let (authIcon, authMessage) = getAuthStatusInfo()
        let (icon, message, url) = getExtensionStatusInfo()
        return .init(
            icon: authIcon ?? icon ?? okIcon,
            inProgress: clsStatus.status == .inProgress,
            message: message,
            url: url,
            authMessage: authMessage
        )
    }

    private func getAuthStatusInfo() -> (authIcon: StatusResponse.Icon?, authMessage: String) {
        switch authStatus.status {
        case .unknown,
            .loggedIn:
            (authIcon: nil, authMessage: "Logged in as \(authStatus.username ?? "")")
        case .notLoggedIn:
            (authIcon: errorIcon, authMessage: authStatus.message ?? "Not logged in")
        }
    }

    private func getExtensionStatusInfo() -> (icon: StatusResponse.Icon?, message: String?, url: String?) {
        if clsStatus.isInactiveStatus {
            return (icon: inactiveIcon, message: clsStatus.message, url: nil)
        } else if clsStatus.isErrorStatus {
            return (icon: errorIcon, message: clsStatus.message, url: nil)
        }

        if extensionStatus == .failed {
            // TODO differentiate between the permission not being granted and the
            // extension just getting disabled by Xcode.
            return (
                icon: errorIcon,
                message: """
                  Extension is not enabled. Enable GitHub Copilot under Xcode
                  and then restart Xcode.
                  """,
                url: "x-apple.systempreferences:com.apple.ExtensionsPreferences"
            )
        }

        switch getAXStatus() {
        case .granted:
            return (icon: nil, message: nil, url: nil)
        case .notGranted:
            return (
                icon: errorIcon,
                message: """
                  Accessibility permission not granted. \
                  Click to open System Preferences.
                  """,
                url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            )
        case .unknown:
            return (
                icon: errorIcon,
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
