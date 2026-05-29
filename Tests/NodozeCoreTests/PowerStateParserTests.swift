import Testing

@testable import NodozeCore

@Test func detectsDisabledSleep() {
    let output = """
    System-wide power settings:
     sleep                1
     disablesleep         1
     displaysleep         10
    """

    #expect(PowerStateParser.sleepIsDisabled(in: output))
}

@Test func treatsMissingDisableSleepAsFalse() {
    let output = """
    System-wide power settings:
     sleep                1
     displaysleep         10
    """

    #expect(!PowerStateParser.sleepIsDisabled(in: output))
}
