import Foundation
import IOKit.pwr_mgt

enum PowerManagerError: LocalizedError {
    case commandFailed(command: String, status: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(command, status, output):
            let detail = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return detail.isEmpty
                ? "\(command) failed with status \(status)."
                : "\(command) failed with status \(status): \(detail)"
        }
    }
}

@MainActor
final class PowerManager {
    private var systemAssertionIDs: [IOPMAssertionID] = []
    private var displayAssertionID: IOPMAssertionID?

    func sleepIsDisabled() async -> Bool {
        Self.persistentSleepIsDisabled() || !systemAssertionIDs.isEmpty
    }

    func setSleepDisabled(_ disabled: Bool, allowDisplaySleep: Bool) async throws {
        if disabled {
            do {
                try setPersistentSleepDisabled(true)
                try acquireAssertions(allowDisplaySleep: allowDisplaySleep)
            } catch {
                releaseAssertions()
                throw error
            }
        } else {
            try setPersistentSleepDisabled(false)
            releaseAssertions()
        }
    }

    func updateDisplaySleepAllowed(_ allowed: Bool) throws {
        guard !systemAssertionIDs.isEmpty else { return }
        try updateDisplaySleepAssertion(allowDisplaySleep: allowed)
    }

    private func acquireAssertions(allowDisplaySleep: Bool) throws {
        guard systemAssertionIDs.isEmpty else {
            try updateDisplaySleepAssertion(allowDisplaySleep: allowDisplaySleep)
            return
        }

        var createdIDs: [IOPMAssertionID] = []
        do {
            createdIDs.append(try createAssertion(
                type: kIOPMAssertionTypeNoIdleSleep as CFString,
                name: "nodoze keeps idle sleep disabled"
            ))
            createdIDs.append(try createAssertion(
                type: kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                name: "nodoze keeps this Mac awake"
            ))
            createdIDs.append(try createAssertion(
                type: kIOPMAssertionTypePreventSystemSleep as CFString,
                name: "nodoze keeps agents running"
            ))
            systemAssertionIDs = createdIDs
            try updateDisplaySleepAssertion(allowDisplaySleep: allowDisplaySleep)
        } catch {
            for id in createdIDs {
                IOPMAssertionRelease(id)
            }
            if let displayAssertionID {
                IOPMAssertionRelease(displayAssertionID)
                self.displayAssertionID = nil
            }
            systemAssertionIDs.removeAll()
            throw error
        }
    }

    private func releaseAssertions() {
        for id in systemAssertionIDs {
            IOPMAssertionRelease(id)
        }
        systemAssertionIDs.removeAll()

        if let displayAssertionID {
            IOPMAssertionRelease(displayAssertionID)
            self.displayAssertionID = nil
        }
    }

    private func updateDisplaySleepAssertion(allowDisplaySleep: Bool) throws {
        if allowDisplaySleep {
            if let displayAssertionID {
                IOPMAssertionRelease(displayAssertionID)
                self.displayAssertionID = nil
            }
            return
        }

        guard displayAssertionID == nil else { return }

        displayAssertionID = try createAssertion(
            type: kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            name: "nodoze keeps the display awake"
        )
    }

    private func createAssertion(type: CFString, name: String) throws -> IOPMAssertionID {
        var assertionID = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            type,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            name as CFString,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            throw PowerManagerError.commandFailed(
                command: "IOPMAssertionCreateWithName \(type)",
                status: Int32(result),
                output: ""
            )
        }

        return assertionID
    }

    private func setPersistentSleepDisabled(_ disabled: Bool) throws {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = [
            "-n",
            "/usr/bin/pmset",
            "-a",
            "disablesleep",
            disabled ? "1" : "0",
        ]
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PowerManagerError.commandFailed(
                command: "pmset disablesleep",
                status: process.terminationStatus,
                output: String(data: data, encoding: .utf8) ?? ""
            )
        }
    }

    private static func persistentSleepIsDisabled() -> Bool {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return false
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return false }

        return output
            .split(separator: "\n")
            .contains { line in
                let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                return parts.first == "SleepDisabled" && parts.dropFirst().first == "1"
            }
    }
}
