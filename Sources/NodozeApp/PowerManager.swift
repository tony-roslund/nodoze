import Foundation
import NodozeCore

enum PowerManagerError: LocalizedError {
    case commandFailed(command: String, status: Int32, output: String)
    case helperMissing(path: String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(command, status, output):
            let detail = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return detail.isEmpty
                ? "\(command) failed with status \(status)."
                : "\(command) failed with status \(status): \(detail)"
        case let .helperMissing(path):
            return "nodoze helper is not installed at \(path). Install nodoze with the installer package, then try again."
        }
    }
}

struct PowerManager {
    private static let helperPath = "/Library/PrivilegedHelperTools/io.nodoze.helper"

    func sleepIsDisabled() async -> Bool {
        if FileManager.default.isExecutableFile(atPath: Self.helperPath),
           let helperOutput = try? await run(Self.helperPath, arguments: ["--sleep-is-disabled"]) {
            return helperOutput.trimmingCharacters(in: .whitespacesAndNewlines) == "1"
        }

        let outputs = [
            try? await run("/usr/bin/pmset", arguments: ["-g"]),
            try? await run("/usr/bin/pmset", arguments: ["-g", "custom"])
        ]
        .compactMap(\.self)
        .joined(separator: "\n")

        return PowerStateParser.sleepIsDisabled(in: outputs)
    }

    func setSleepDisabled(_ disabled: Bool) async throws {
        let value = disabled ? "1" : "0"

        guard FileManager.default.isExecutableFile(atPath: Self.helperPath) else {
            throw PowerManagerError.helperMissing(path: Self.helperPath)
        }

        _ = try await run(Self.helperPath, arguments: ["--set-sleep-disabled", value])
    }

    private func run(_ executable: String, arguments: [String]) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let output = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = output
            process.standardError = output

            try process.run()
            process.waitUntilExit()

            let data = output.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? ""

            guard process.terminationStatus == 0 else {
                throw PowerManagerError.commandFailed(
                    command: ([executable] + arguments).joined(separator: " "),
                    status: process.terminationStatus,
                    output: text
                )
            }

            return text
        }
        .value
    }
}
