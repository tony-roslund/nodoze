import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    static let currentVersion = "0.1.0"

    @Published private(set) var sleepDisabled = false
    @Published private(set) var isBusy = false
    @Published private(set) var openAtLogin = false
    @Published var automaticUpdateChecks: Bool {
        didSet {
            defaults.set(automaticUpdateChecks, forKey: DefaultsKey.automaticUpdateChecks)
        }
    }
    @Published private(set) var statusMessage = "Ready."

    var onAbout: () -> Void = {}

    private enum DefaultsKey {
        static let automaticUpdateChecks = "automaticUpdateChecks"
    }

    private let defaults: UserDefaults
    private let powerManager: PowerManager
    private let loginItemManager: LoginItemManager
    private let updateService: UpdateService

    init(
        defaults: UserDefaults = .standard,
        powerManager: PowerManager = PowerManager(),
        loginItemManager: LoginItemManager = LoginItemManager(),
        updateService: UpdateService = UpdateService()
    ) {
        self.defaults = defaults
        self.powerManager = powerManager
        self.loginItemManager = loginItemManager
        self.updateService = updateService
        automaticUpdateChecks = defaults.object(forKey: DefaultsKey.automaticUpdateChecks) as? Bool ?? true
        openAtLogin = loginItemManager.isEnabled
    }

    func refreshPowerState() {
        Task {
            sleepDisabled = await powerManager.sleepIsDisabled()
            statusMessage = sleepDisabled ? "Lid-close sleep is disabled." : "Lid-close sleep is normal."
        }
    }

    func toggleSleepDisabled() {
        setSleepDisabled(!sleepDisabled)
    }

    func setSleepDisabled(_ disabled: Bool) {
        guard !isBusy else { return }

        isBusy = true
        statusMessage = disabled ? "Keeping this Mac awake..." : "Restoring normal lid-close sleep..."

        Task {
            do {
                try await powerManager.setSleepDisabled(disabled)
                sleepDisabled = await powerManager.sleepIsDisabled()
                statusMessage = sleepDisabled
                    ? "nodoze is on. Closing the lid will not sleep this Mac."
                    : "nodoze is off. Lid-close sleep is normal."
            } catch {
                statusMessage = error.localizedDescription
            }

            isBusy = false
        }
    }

    func setOpenAtLogin(_ enabled: Bool) {
        do {
            try loginItemManager.setEnabled(enabled)
            openAtLogin = loginItemManager.isEnabled
            statusMessage = openAtLogin ? "nodoze will open at login." : "nodoze will not open at login."
        } catch {
            openAtLogin = loginItemManager.isEnabled
            statusMessage = error.localizedDescription
        }
    }

    func checkForUpdates(silent: Bool = false) {
        if !silent {
            statusMessage = "Checking for updates..."
        }

        Task {
            do {
                switch try await updateService.check(currentVersion: Self.currentVersion) {
                case let .updateAvailable(version, downloadURL):
                    statusMessage = "Version \(version) is available."
                    if let downloadURL {
                        NSWorkspace.shared.open(downloadURL)
                    }
                case .current:
                    statusMessage = "nodoze \(Self.currentVersion) is up to date."
                }
            } catch {
                if !silent {
                    statusMessage = "Updates are not available yet."
                }
            }
        }
    }
}
