import XCTest

final class TestSpeechAnalysisErrors: XCTestCase {
    func testAnalyzePronunciation_unauthorized() throws {
        throw XCTSkip("Pending implementation: 401 Unauthorized contract test")
    }

    func testAnalyzePronunciation_rateLimited() throws {
        throw XCTSkip("Pending implementation: 429 Rate limit contract test")
    }

    func testAnalyzePronunciation_serverError() throws {
        throw XCTSkip("Pending implementation: 500 Server error contract test")
    }
}


