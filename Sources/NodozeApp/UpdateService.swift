import Foundation
import NodozeCore

struct UpdateManifest: Decodable {
    let version: String
    let downloadURL: URL?
    let releaseNotesURL: URL?
}

enum UpdateCheckResult {
    case updateAvailable(version: String, downloadURL: URL?)
    case current
}

struct UpdateService {
    private let manifestURL = URL(string: "https://nodoze.io/appcast.json")!

    func check(currentVersion: String) async throws -> UpdateCheckResult {
        let (data, _) = try await URLSession.shared.data(from: manifestURL)
        let manifest = try JSONDecoder().decode(UpdateManifest.self, from: data)

        if SemanticVersion(manifest.version) > SemanticVersion(currentVersion) {
            return .updateAvailable(version: manifest.version, downloadURL: manifest.downloadURL)
        }

        return .current
    }
}
