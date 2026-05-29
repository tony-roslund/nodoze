import Foundation
import NodozeCore

enum HelperError: Error {
    case invalidArguments
    case requiresRoot
    case commandFailed(status: Int32, output: String)
}

@main
struct NodozeHelper {
    static func main() async {
        do {
            try await run(arguments: Array(CommandLine.arguments.dropFirst()))
            exit(EXIT_SUCCESS)
        } catch {
            FileHandle.standardError.write(Data("\(message(for: error))\n".utf8))
            exit(EXIT_FAILURE)
        }
    }

    private static func run(arguments: [String]) async throws {
        switch arguments {
        case ["--sleep-is-disabled"]:
            let output = try await runPMSet(arguments: ["-g", "custom"])
            let disabled = PowerStateParser.sleepIsDisabled(in: output)
            print(disabled ? "1" : "0")

        case ["--set-sleep-disabled", "0"]:
            try requireRoot()
            _ = try await runPMSet(arguments: ["-a", "disablesleep", "0"])

        case ["--set-sleep-disabled", "1"]:
            try requireRoot()
            _ = try await runPMSet(arguments: ["-a", "disablesleep", "1"])

        default:
            throw HelperError.invalidArguments
        }
    }

    private static func requireRoot() throws {
        guard geteuid() == 0 else {
            throw HelperError.requiresRoot
        }
    }

    private static func runPMSet(arguments: [String]) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let output = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            process.arguments = arguments
            process.standardOutput = output
            process.standardError = output

            try process.run()
            process.waitUntilExit()

            let data = output.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? ""

            guard process.terminationStatus == 0 else {
                throw HelperError.commandFailed(status: process.terminationStatus, output: text)
            }

            return text
        }
        .value
    }

    private static func message(for error: Error) -> String {
        switch error {
        case HelperError.invalidArguments:
            return "Invalid nodoze helper arguments."
        case HelperError.requiresRoot:
            return "nodoze helper must be installed by the nodoze installer."
        case let HelperError.commandFailed(status, output):
            let detail = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return detail.isEmpty ? "pmset failed with status \(status)." : "pmset failed with status \(status): \(detail)"
        default:
            return error.localizedDescription
        }
    }
}
