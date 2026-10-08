import XCTest
@testable import MenuBarKit

private struct Sample: Codable, Equatable, DefaultInitializable {
    var count = 1
    var names: [String] = []
}

final class JSONDefaultsStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        suiteName = "MenuBarKitTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func test_loadWithoutSavedValueReturnsDefault() {
        XCTAssertEqual(JSONDefaultsStore<Sample>(defaults: defaults).load(), Sample())
    }

    func test_saveThenLoadRoundTrips() {
        let store = JSONDefaultsStore<Sample>(defaults: defaults)
        store.save(Sample(count: 5, names: ["a"]))
        XCTAssertEqual(JSONDefaultsStore<Sample>(defaults: defaults).load(), Sample(count: 5, names: ["a"]))
    }

    func test_corruptDataReturnsDefault() {
        defaults.set(Data("not json".utf8), forKey: "config")
        XCTAssertEqual(JSONDefaultsStore<Sample>(defaults: defaults).load(), Sample())
    }

    func test_customKeysAreIsolated() {
        let a = JSONDefaultsStore<Sample>(defaults: defaults, key: "a")
        let b = JSONDefaultsStore<Sample>(defaults: defaults, key: "b")
        a.save(Sample(count: 9))
        XCTAssertEqual(b.load(), Sample())
    }
}
