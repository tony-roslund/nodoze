import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private let settingsWindowController = SettingsWindowController()
    private var statusController: StatusController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        model.onAbout = { [weak self] in
            self?.showAbout()
        }

        statusController = StatusController(
            model: model,
            openSettings: { [weak self] in self?.showSettings() },
            showAbout: { [weak self] in self?.showAbout() }
        )

        model.refreshPowerState()

        if model.automaticUpdateChecks {
            model.checkForUpdates(silent: true)
        }
    }

    private func showSettings() {
        settingsWindowController.show(model: model)
    }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "nodoze"
        alert.informativeText = "Version \(AppModel.currentVersion)\n\nBuilt by 74Lab."
        alert.addButton(withTitle: "Done")
        alert.alertStyle = .informational
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
