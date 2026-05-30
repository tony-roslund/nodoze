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
    private var assertionIDs: [IOPMAssertionID] = []

    func sleepIsDisabled() async -> Bool {
        !assertionIDs.isEmpty
    }

    func setSleepDisabled(_ disabled: Bool) async throws {
        if disabled {
            try acquireAssertions()
        } else {
            releaseAssertions()
        }
    }

    private func acquireAssertions() throws {
        guard assertionIDs.isEmpty else { return }

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
            assertionIDs = createdIDs
        } catch {
            for id in createdIDs {
                IOPMAssertionRelease(id)
            }
            throw error
        }
    }

    private func releaseAssertions() {
        for id in assertionIDs {
            IOPMAssertionRelease(id)
        }
        assertionIDs.removeAll()
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
}
