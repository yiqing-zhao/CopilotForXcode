import Logger
import Preferences
import Sparkle

public protocol UpdateCheckerProtocol {
    func checkForUpdates()
    func getAutomaticallyChecksForUpdates() -> Bool
    func setAutomaticallyChecksForUpdates(_ value: Bool)
}

public protocol UpdateCheckerDelegate: AnyObject {
    func prepareForRelaunch(finish: @escaping () -> Void)
}

public final class NoopUpdateChecker: UpdateCheckerProtocol {
    public init() {}
    public func checkForUpdates() {}
    public func getAutomaticallyChecksForUpdates() -> Bool { false }
    public func setAutomaticallyChecksForUpdates(_ value: Bool) {}
}

public final class UpdateChecker: UpdateCheckerProtocol {
    let updater: SPUUpdater
    let delegate = UpdaterDelegate()

    public init(hostBundle: Bundle, checkerDelegate: UpdateCheckerDelegate) {
        updater = SPUUpdater(
            hostBundle: hostBundle,
            applicationBundle: Bundle.main,
            userDriver: SPUStandardUserDriver(hostBundle: hostBundle, delegate: nil),
            delegate: delegate
        )
        delegate.updateCheckerDelegate = checkerDelegate
        do {
            try updater.start()
        } catch {
            Logger.updateChecker.error(error.localizedDescription)
        }
    }

    public convenience init?(hostBundle: Bundle?, checkerDelegate: UpdateCheckerDelegate) {
        guard let hostBundle = hostBundle else { return nil }
        self.init(hostBundle: hostBundle, checkerDelegate: checkerDelegate)
    }

    public func checkForUpdates() {
        updater.checkForUpdates()
    }

    public func getAutomaticallyChecksForUpdates() -> Bool {
        updater.automaticallyChecksForUpdates
    }

    public func setAutomaticallyChecksForUpdates(_ value: Bool) {
        updater.automaticallyChecksForUpdates = value
    }
}

class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    weak var updateCheckerDelegate: UpdateCheckerDelegate?

    func updater(
        _ updater: SPUUpdater,
        shouldPostponeRelaunchForUpdate item: SUAppcastItem,
        untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
        if let updateCheckerDelegate {
            updateCheckerDelegate.prepareForRelaunch(finish: installHandler)
            return true
        }
        return false
    }

    func allowedChannels(for updater: SPUUpdater) -> Set<String> {
        if UserDefaults.shared.value(for: \.installPrereleases) {
            Set(["prerelease"])
        } else {
            []
        }
    }
}

