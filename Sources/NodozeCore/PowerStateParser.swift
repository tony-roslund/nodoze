import Foundation

public enum PowerStateParser {
    public static func sleepIsDisabled(in pmsetOutput: String) -> Bool {
        pmsetOutput
            .split(whereSeparator: \.isNewline)
            .contains { line in
                let parts = line.split(whereSeparator: \.isWhitespace)
                guard parts.count >= 2 else { return false }
                return parts[0] == "disablesleep" && parts[1] == "1"
            }
    }
}
