import Foundation
import Testing
@testable import YawnCast

struct SupportMailTests {
    @Test func draftGoesToSupportWithTheNoteFirst() throws {
        let body = SupportMail.body(problem: "  Sleep timer stops early & skips 😴  ")
        #expect(body.hasPrefix("Sleep timer stops early & skips 😴\n\n--- Debug logs"))
        #expect(body.contains("Errors logged since the app opened:"))
        let url = try #require(SupportMail.url(body: body))
        let parts = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(parts.scheme == "mailto")
        #expect(parts.path == SupportMail.address)
        #expect(parts.queryItems?.first { $0.name == "body" }?.value == body)
        #expect(parts.queryItems?.first { $0.name == "subject" }?.value?.hasSuffix("debug logs") == true)
    }
}
