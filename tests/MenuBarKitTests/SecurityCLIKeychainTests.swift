import XCTest
@testable import MenuBarKit

final class SecurityCLIKeychainTests: XCTestCase {
    private var keychain: SecurityCLIKeychain!

    override func setUp() {
        keychain = SecurityCLIKeychain(service: "MenuBarKitTests-\(UUID().uuidString)", account: "acct")
    }

    override func tearDown() {
        try? keychain.delete()
    }

    func test_readMissingReturnsNil() throws {
        XCTAssertNil(try keychain.read())
    }

    func test_saveThenReadRoundTrips() throws {
        try keychain.save("ghp_abc123")
        XCTAssertEqual(try keychain.read(), "ghp_abc123")
    }

    func test_saveOverwrites() throws {
        try keychain.save("one")
        try keychain.save("two")
        XCTAssertEqual(try keychain.read(), "two")
    }

    func test_deleteRemoves() throws {
        try keychain.save("x")
        try keychain.delete()
        XCTAssertNil(try keychain.read())
    }

    func test_saveTrimsSurroundingWhitespace() throws {
        try keychain.save("  tok  \n")
        XCTAssertEqual(try keychain.read(), "tok")
    }

    func test_saveRejectsEmptyAndEmbeddedNewlines() {
        XCTAssertThrowsError(try keychain.save("   ")) {
            XCTAssertEqual($0 as? SecurityCLIKeychainError, .writeFailed)
        }
        XCTAssertThrowsError(try keychain.save("a\nb")) {
            XCTAssertEqual($0 as? SecurityCLIKeychainError, .writeFailed)
        }
    }

    func test_tokenWithQuoteAndBackslashRoundTrips() throws {
        let tricky = #"a"b\c d"#
        try keychain.save(tricky)
        XCTAssertEqual(try keychain.read(), tricky)
    }

    func test_quoteEscapesBackslashAndQuote() {
        XCTAssertEqual(SecurityCLIKeychain.quote(#"a"b\c"#), #""a\"b\\c""#)
    }
}
