import AppKit
import Combine

@MainActor
final class StatusController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let model: AppModel
    private let openSettings: () -> Void
    private let showAbout: () -> Void
    private var cancellables = Set<AnyCancellable>()
    private var eyeTrackingTimer: Timer?
    private var blinkTimer: Timer?
    private var leftPupilOffset = CGPoint.zero
    private var rightPupilOffset = CGPoint.zero
    private var isBlinking = false
    private var sleepingPhase = 0

    init(model: AppModel, openSettings: @escaping () -> Void, showAbout: @escaping () -> Void) {
        self.model = model
        self.openSettings = openSettings
        self.showAbout = showAbout
        super.init()
        configureStatusItem()
        startEyeAnimation()
        bindModel()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.target = self
        button.action = #selector(handleStatusButton)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem.length = 56
        button.imagePosition = .imageOnly
        button.toolTip = "nodoze"
        updateIcon()
    }

    private func bindModel() {
        model.$sleepDisabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateIcon() }
            .store(in: &cancellables)

        model.$isBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateIcon() }
            .store(in: &cancellables)
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }

        button.image = EyesIconFactory.make(
            enabled: model.sleepDisabled,
            busy: model.isBusy,
            leftPupilOffset: leftPupilOffset,
            rightPupilOffset: rightPupilOffset,
            blinking: isBlinking,
            sleepingPhase: sleepingPhase
        )
        button.contentTintColor = nil
        button.toolTip = model.sleepDisabled
            ? "nodoze is on. Right-click for settings."
            : "nodoze is off. Right-click for settings."
    }

    private func startEyeAnimation() {
        eyeTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePupilOffsets()
            }
        }

        blinkTimer = Timer.scheduledTimer(withTimeInterval: 5.4, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.model.isBusy else { return }

                if !self.model.sleepDisabled {
                    self.sleepingPhase = (self.sleepingPhase + 1) % 3
                    self.updateIcon()
                    return
                }

                self.isBlinking = true
                self.updateIcon()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { [weak self] in
                    self?.isBlinking = false
                    self?.updateIcon()
                }
            }
        }
    }

    private func updatePupilOffsets() {
        guard model.sleepDisabled, !model.isBusy, let button = statusItem.button, let window = button.window else {
            if leftPupilOffset != .zero || rightPupilOffset != .zero {
                leftPupilOffset = .zero
                rightPupilOffset = .zero
                updateIcon()
            }
            return
        }

        let buttonRect = window.convertToScreen(button.convert(button.bounds, to: nil))
        let center = CGPoint(x: buttonRect.midX, y: buttonRect.midY)
        let mouse = NSEvent.mouseLocation
        let dx = mouse.x - center.x
        let dy = mouse.y - center.y
        let distance = max(sqrt(dx * dx + dy * dy), 1)
        let near = distance < 80
        let maxX: CGFloat = 2.8
        let maxY: CGFloat = 2.3
        let strength = min(distance / 55, 1)

        if near {
            leftPupilOffset = CGPoint(x: maxX * 0.9, y: (dy / distance) * maxY * strength)
            rightPupilOffset = CGPoint(x: -maxX * 0.9, y: (dy / distance) * maxY * strength)
        } else {
            let shared = CGPoint(
                x: (dx / distance) * maxX * strength,
                y: (dy / distance) * maxY * strength
            )
            leftPupilOffset = shared
            rightPupilOffset = shared
        }

        updateIcon()
    }

    @objc private func handleStatusButton() {
        guard let event = NSApp.currentEvent else {
            model.toggleSleepDisabled()
            return
        }

        if event.type == .rightMouseDown || event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            openMenu()
            return
        }

        model.toggleSleepDisabled()
    }

    private func openMenu() {
        let menu = NSMenu()

        let status = NSMenuItem(
            title: model.sleepDisabled ? "nodoze is On" : "nodoze is Off",
            action: nil,
            keyEquivalent: ""
        )
        status.isEnabled = false
        menu.addItem(status)

        menu.addItem(NSMenuItem(
            title: model.sleepDisabled ? "Allow Sleep on Lid Close" : "Keep Awake with Lid Closed",
            action: #selector(toggleSleepDisabled),
            keyEquivalent: ""
        ))

        menu.addItem(.separator())

        let openAtLogin = NSMenuItem(title: "Open at Login", action: #selector(toggleOpenAtLogin), keyEquivalent: "")
        openAtLogin.state = model.openAtLogin ? .on : .off
        menu.addItem(openAtLogin)

        let automaticUpdates = NSMenuItem(
            title: "Check for Updates Automatically",
            action: #selector(toggleAutomaticUpdateChecks),
            keyEquivalent: ""
        )
        automaticUpdates.state = model.automaticUpdateChecks ? .on : .off
        menu.addItem(automaticUpdates)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettingsItem), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "u"))
        menu.addItem(NSMenuItem(title: "About nodoze", action: #selector(showAboutItem), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit nodoze", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleSleepDisabled() {
        model.toggleSleepDisabled()
    }

    @objc private func openSettingsItem() {
        openSettings()
    }

    @objc private func toggleOpenAtLogin() {
        model.setOpenAtLogin(!model.openAtLogin)
    }

    @objc private func toggleAutomaticUpdateChecks() {
        model.setAutomaticUpdateChecks(!model.automaticUpdateChecks)
    }

    @objc private func checkForUpdates() {
        model.checkForUpdates()
    }

    @objc private func showAboutItem() {
        showAbout()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
