import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    static let currentVersion = "0.1.0"

    @Published private(set) var sleepDisabled = false
    @Published private(set) var isBusy = false
    @Published private(set) var openAtLogin = false
    @Published private(set) var keepActiveUntilAgentsFinish = false
    @Published private(set) var monitorCodex = true
    @Published private(set) var monitorClaudeCode = true
    @Published private(set) var monitorCursor = true
    @Published private(set) var monitorTerminalCLIs = true
    @Published private(set) var monitorConductor = true
    @Published private(set) var monitorSuperset = true
    @Published private(set) var customAgentProcessNames = ""
    @Published private(set) var agentIdleGraceMinutes = 10
    @Published private(set) var menuBarIconStyle: MenuBarIconStyle = .fullColor
    @Published var automaticUpdateChecks: Bool {
        didSet {
            defaults.set(automaticUpdateChecks, forKey: DefaultsKey.automaticUpdateChecks)
        }
    }
    @Published private(set) var allowDisplaySleepWhileActive = true
    @Published private(set) var agentActivitySummary = "Agent monitor is off."
    @Published private(set) var statusMessage = "Ready."

    var onAbout: () -> Void = {}

    private enum DefaultsKey {
        static let automaticUpdateChecks = "automaticUpdateChecks"
        static let allowDisplaySleepWhileActive = "allowDisplaySleepWhileActive"
        static let keepActiveUntilAgentsFinish = "keepActiveUntilAgentsFinish"
        static let monitorCodex = "monitorCodex"
        static let monitorClaudeCode = "monitorClaudeCode"
        static let monitorCursor = "monitorCursor"
        static let monitorTerminalCLIs = "monitorTerminalCLIs"
        static let monitorConductor = "monitorConductor"
        static let monitorSuperset = "monitorSuperset"
        static let customAgentProcessNames = "customAgentProcessNames"
        static let agentIdleGraceMinutes = "agentIdleGraceMinutes"
        static let menuBarIconStyle = "menuBarIconStyle"
    }

    private let defaults: UserDefaults
    private let powerManager: PowerManager
    private let loginItemManager: LoginItemManager
    private let updateService: UpdateService
    private let agentActivityMonitor: AgentActivityMonitor
    private var agentMonitorTimer: Timer?
    private var agentMonitorTask: Task<Void, Never>?
    private var lastAgentActivityAt: Date?

    init(
        defaults: UserDefaults = .standard,
        powerManager: PowerManager = PowerManager(),
        loginItemManager: LoginItemManager = LoginItemManager(),
        updateService: UpdateService = UpdateService(),
        agentActivityMonitor: AgentActivityMonitor = AgentActivityMonitor()
    ) {
        self.defaults = defaults
        self.powerManager = powerManager
        self.loginItemManager = loginItemManager
        self.updateService = updateService
        self.agentActivityMonitor = agentActivityMonitor
        automaticUpdateChecks = defaults.object(forKey: DefaultsKey.automaticUpdateChecks) as? Bool ?? true
        allowDisplaySleepWhileActive = defaults.object(forKey: DefaultsKey.allowDisplaySleepWhileActive) as? Bool ?? true
        keepActiveUntilAgentsFinish = defaults.object(forKey: DefaultsKey.keepActiveUntilAgentsFinish) as? Bool ?? false
        monitorCodex = defaults.object(forKey: DefaultsKey.monitorCodex) as? Bool ?? true
        monitorClaudeCode = defaults.object(forKey: DefaultsKey.monitorClaudeCode) as? Bool ?? true
        monitorCursor = defaults.object(forKey: DefaultsKey.monitorCursor) as? Bool ?? true
        monitorTerminalCLIs = defaults.object(forKey: DefaultsKey.monitorTerminalCLIs) as? Bool ?? true
        monitorConductor = defaults.object(forKey: DefaultsKey.monitorConductor) as? Bool ?? true
        monitorSuperset = defaults.object(forKey: DefaultsKey.monitorSuperset) as? Bool ?? true
        customAgentProcessNames = defaults.string(forKey: DefaultsKey.customAgentProcessNames) ?? ""
        let savedGrace = defaults.integer(forKey: DefaultsKey.agentIdleGraceMinutes)
        agentIdleGraceMinutes = savedGrace > 0 ? savedGrace : 10
        if let savedStyle = defaults.string(forKey: DefaultsKey.menuBarIconStyle),
           let style = MenuBarIconStyle(rawValue: savedStyle) {
            menuBarIconStyle = style
        }
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
                try await powerManager.setSleepDisabled(disabled, allowDisplaySleep: allowDisplaySleepWhileActive)
                sleepDisabled = await powerManager.sleepIsDisabled()
                statusMessage = sleepDisabled
                    ? "nodoze is on. Closing the lid will not sleep this Mac."
                    : "nodoze is off. Lid-close sleep is normal."
                configureAgentMonitoring()
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

    func setAllowDisplaySleepWhileActive(_ enabled: Bool) {
        allowDisplaySleepWhileActive = enabled
        defaults.set(enabled, forKey: DefaultsKey.allowDisplaySleepWhileActive)

        guard sleepDisabled else {
            statusMessage = enabled
                ? "The display may sleep while nodoze is active."
                : "The display will stay awake while nodoze is active."
            return
        }

        Task {
            do {
                try powerManager.updateDisplaySleepAllowed(enabled)
                statusMessage = enabled
                    ? "The display may sleep while nodoze is active."
                    : "The display will stay awake while nodoze is active."
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    func setAutomaticUpdateChecks(_ enabled: Bool) {
        automaticUpdateChecks = enabled
        statusMessage = automaticUpdateChecks
            ? "nodoze will check for updates automatically."
            : "Automatic update checks are off."
    }

    func setKeepActiveUntilAgentsFinish(_ enabled: Bool) {
        keepActiveUntilAgentsFinish = enabled
        defaults.set(enabled, forKey: DefaultsKey.keepActiveUntilAgentsFinish)
        statusMessage = enabled
            ? "nodoze will turn off after monitored agents go quiet."
            : "Agent activity monitoring is off."
        configureAgentMonitoring()
    }

    func setMonitorCodex(_ enabled: Bool) {
        monitorCodex = enabled
        defaults.set(enabled, forKey: DefaultsKey.monitorCodex)
        refreshAgentMonitoringConfiguration()
    }

    func setMonitorClaudeCode(_ enabled: Bool) {
        monitorClaudeCode = enabled
        defaults.set(enabled, forKey: DefaultsKey.monitorClaudeCode)
        refreshAgentMonitoringConfiguration()
    }

    func setMonitorCursor(_ enabled: Bool) {
        monitorCursor = enabled
        defaults.set(enabled, forKey: DefaultsKey.monitorCursor)
        refreshAgentMonitoringConfiguration()
    }

    func setMonitorTerminalCLIs(_ enabled: Bool) {
        monitorTerminalCLIs = enabled
        defaults.set(enabled, forKey: DefaultsKey.monitorTerminalCLIs)
        refreshAgentMonitoringConfiguration()
    }

    func setMonitorConductor(_ enabled: Bool) {
        monitorConductor = enabled
        defaults.set(enabled, forKey: DefaultsKey.monitorConductor)
        refreshAgentMonitoringConfiguration()
    }

    func setMonitorSuperset(_ enabled: Bool) {
        monitorSuperset = enabled
        defaults.set(enabled, forKey: DefaultsKey.monitorSuperset)
        refreshAgentMonitoringConfiguration()
    }

    func setCustomAgentProcessNames(_ names: String) {
        customAgentProcessNames = names
        defaults.set(names, forKey: DefaultsKey.customAgentProcessNames)
        refreshAgentMonitoringConfiguration()
    }

    func setAgentIdleGraceMinutes(_ minutes: Int) {
        let clamped = max(1, min(120, minutes))
        agentIdleGraceMinutes = clamped
        defaults.set(clamped, forKey: DefaultsKey.agentIdleGraceMinutes)
        refreshAgentMonitoringConfiguration()
    }

    func setMenuBarIconStyle(_ style: MenuBarIconStyle) {
        menuBarIconStyle = style
        defaults.set(style.rawValue, forKey: DefaultsKey.menuBarIconStyle)
        statusMessage = style == .monochrome
            ? "Menu bar icon set to monochrome."
            : "Menu bar icon set to full color."
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

    private func configureAgentMonitoring() {
        agentMonitorTimer?.invalidate()
        agentMonitorTimer = nil
        agentMonitorTask?.cancel()
        agentMonitorTask = nil

        guard sleepDisabled, keepActiveUntilAgentsFinish else {
            lastAgentActivityAt = nil
            agentActivitySummary = keepActiveUntilAgentsFinish
                ? "Agent monitor starts when nodoze is on."
                : "Agent monitor is off."
            return
        }

        lastAgentActivityAt = Date()
        agentActivitySummary = "Checking monitored agents..."
        runAgentActivityCheck()

        agentMonitorTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.runAgentActivityCheck()
            }
        }
    }

    private func refreshAgentMonitoringConfiguration() {
        guard sleepDisabled, keepActiveUntilAgentsFinish else { return }

        lastAgentActivityAt = Date()
        agentActivitySummary = "Checking monitored agents..."
        runAgentActivityCheck()
    }

    private func runAgentActivityCheck() {
        guard agentMonitorTask == nil else { return }

        let configuration = AgentMonitorConfiguration(
            monitorCodex: monitorCodex,
            monitorClaudeCode: monitorClaudeCode,
            monitorCursor: monitorCursor,
            monitorTerminalCLIs: monitorTerminalCLIs,
            monitorConductor: monitorConductor,
            monitorSuperset: monitorSuperset,
            customProcessNames: parsedCustomAgentProcessNames
        )

        agentMonitorTask = Task { [weak self] in
            guard let self else { return }

            let report = agentActivityMonitor.report(configuration: configuration)
            guard !Task.isCancelled else { return }

            self.agentMonitorTask = nil
            self.handleAgentActivityReport(report)
        }
    }

    private func handleAgentActivityReport(_ report: AgentActivityReport) {
        guard sleepDisabled, keepActiveUntilAgentsFinish else {
            agentActivitySummary = "Agent monitor is off."
            return
        }

        if report.isActive {
            lastAgentActivityAt = Date()
            agentActivitySummary = report.summary
            return
        }

        let lastActivityAt = lastAgentActivityAt ?? Date()
        let elapsedSeconds = Date().timeIntervalSince(lastActivityAt)
        let graceSeconds = TimeInterval(agentIdleGraceMinutes * 60)
        let remainingSeconds = max(0, graceSeconds - elapsedSeconds)

        if remainingSeconds > 0 {
            agentActivitySummary = "No selected agents active. Turning off in \(Self.minutesText(remainingSeconds))."
            return
        }

        agentActivitySummary = "No selected agents active. Turning nodoze off."
        statusMessage = "No monitored agents were active for \(agentIdleGraceMinutes) min."
        setSleepDisabled(false)
    }

    private var parsedCustomAgentProcessNames: [String] {
        customAgentProcessNames
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func minutesText(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int(ceil(seconds / 60)))
        return minutes == 1 ? "1 min" : "\(minutes) min"
    }
}
