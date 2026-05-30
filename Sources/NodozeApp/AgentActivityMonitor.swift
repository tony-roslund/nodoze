import Foundation

struct AgentMonitorConfiguration: Sendable {
    var monitorCodex: Bool
    var monitorClaudeCode: Bool
    var monitorCursor: Bool
    var monitorTerminalCLIs: Bool
    var customProcessNames: [String]
}

struct AgentActivityReport: Sendable {
    var isActive: Bool
    var labels: [String]
    var processNames: [String]

    var summary: String {
        guard isActive else {
            return "No selected agents are active."
        }

        let joinedLabels = labels.prefix(3).joined(separator: ", ")
        if labels.count > 3 {
            return "Active: \(joinedLabels), and \(labels.count - 3) more."
        }

        return "Active: \(joinedLabels)."
    }
}

@MainActor
final class AgentActivityMonitor {
    func report(configuration: AgentMonitorConfiguration) -> AgentActivityReport {
        let processes = Self.runningProcesses()
        return Self.report(from: processes, configuration: configuration)
    }

    private static func report(
        from processes: [RunningProcess],
        configuration: AgentMonitorConfiguration
    ) -> AgentActivityReport {
        var labels: [String] = []
        var processNames: [String] = []

        func append(_ label: String, matches: [RunningProcess]) {
            guard !matches.isEmpty else { return }
            if !labels.contains(label) {
                labels.append(label)
            }

            for process in matches.prefix(4) where !processNames.contains(process.displayName) {
                processNames.append(process.displayName)
            }
        }

        if configuration.monitorCodex {
            append("Codex", matches: processes.matchingAny(["codex"]))
        }

        if configuration.monitorClaudeCode {
            append("Claude Code", matches: processes.matchingAny(["claude", "claude-code"]))
        }

        if configuration.monitorCursor {
            let cursorMatches = processes
                .matchingAny(["cursor"])
                .filter { $0.cpuPercent >= 1.0 || $0.command.localizedCaseInsensitiveContains("agent") }
            append("Cursor", matches: cursorMatches)
        }

        if configuration.monitorTerminalCLIs {
            append("Terminal CLI", matches: terminalCommandProcesses(from: processes))
        }

        let customMatches = processes.matchingAny(configuration.customProcessNames)
        for customName in configuration.customProcessNames {
            let matches = customMatches.filter { $0.matches(customName) }
            append(customName, matches: matches)
        }

        return AgentActivityReport(
            isActive: !labels.isEmpty,
            labels: labels,
            processNames: processNames
        )
    }

    private static func runningProcesses() -> [RunningProcess] {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,ppid=,pcpu=,command="]
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { RunningProcess(line: String($0)) }
    }

    private static func terminalCommandProcesses(from processes: [RunningProcess]) -> [RunningProcess] {
        let byPID = Dictionary(uniqueKeysWithValues: processes.map { ($0.pid, $0) })
        let terminalPIDs = Set(processes.filter(\.isTerminalEmulator).map(\.pid))

        return processes.filter { process in
            guard !process.isShellOrTerminalUtility, !process.isTerminalEmulator else {
                return false
            }

            var parentID = process.parentPID
            var visited = Set<Int32>()

            while let parent = byPID[parentID], !visited.contains(parentID) {
                if terminalPIDs.contains(parent.pid) {
                    return true
                }

                visited.insert(parentID)
                parentID = parent.parentPID
            }

            return false
        }
    }
}

private struct RunningProcess: Sendable {
    let pid: Int32
    let parentPID: Int32
    let cpuPercent: Double
    let executablePath: String
    let command: String

    init?(line: String) {
        let parts = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
        guard parts.count >= 4,
              let pid = Int32(parts[0]),
              let parentPID = Int32(parts[1]),
              let cpuPercent = Double(parts[2])
        else {
            return nil
        }

        self.pid = pid
        self.parentPID = parentPID
        self.cpuPercent = cpuPercent
        command = String(parts[3])
        executablePath = String(command.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).first ?? "")
    }

    var executableName: String {
        URL(fileURLWithPath: executablePath).lastPathComponent
    }

    var displayName: String {
        let lowercasedCommand = command.lowercased()
        if lowercasedCommand.contains("codex") { return "Codex" }
        if lowercasedCommand.contains("claude") { return "Claude" }
        if lowercasedCommand.contains("cursor") { return "Cursor" }
        if lowercasedCommand.contains("conductor") { return "Conductor" }
        if lowercasedCommand.contains("superset") { return "Superset" }
        return executableName.isEmpty ? command : executableName
    }

    var isTerminalEmulator: Bool {
        let name = executableName.lowercased()
        let command = command.lowercased()
        return name == "terminal"
            || name == "iterm2"
            || name == "iterm"
            || name == "ghostty"
            || name == "wezterm"
            || name == "alacritty"
            || name == "kitty"
            || name == "warp"
            || command.contains("/terminal.app/")
            || command.contains("/iterm.app/")
            || command.contains("/iterm2.app/")
            || command.contains("/ghostty.app/")
            || command.contains("/warp.app/")
    }

    var isShellOrTerminalUtility: Bool {
        let ignored = Set([
            "bash", "fish", "login", "man", "nano", "screen", "script", "sh",
            "sudo", "su", "tmux", "vim", "zsh"
        ])
        return ignored.contains(executableName.lowercased())
    }

    func matches(_ rawNeedle: String) -> Bool {
        let needle = rawNeedle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return false }

        return executableName.lowercased() == needle
            || executableName.lowercased().contains(needle)
            || command.lowercased().contains(needle)
    }
}

private extension Array where Element == RunningProcess {
    func matchingAny(_ names: [String]) -> [RunningProcess] {
        let normalized = names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalized.isEmpty else { return [] }
        return filter { process in
            normalized.contains { process.matches($0) }
        }
    }
}
