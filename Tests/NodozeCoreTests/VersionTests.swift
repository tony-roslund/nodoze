import Testing

@testable import NodozeCore

@Test func comparesSemanticVersions() {
    #expect(SemanticVersion("0.2.0") > SemanticVersion("0.1.9"))
    #expect(SemanticVersion("1.0") == SemanticVersion("1.0.0"))
    #expect(SemanticVersion("1.0.1") < SemanticVersion("1.1.0"))
}
