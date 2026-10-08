import XCTest
@testable import MenuBarKit

private final class FakeLoginItemManager: LoginItemManaging {
    var isEnabled = false
    var registerCallCount = 0
    var unregisterCallCount = 0
    var shouldThrow = false

    struct FakeError: Error {}

    func register() throws {
        registerCallCount += 1
        if shouldThrow { throw FakeError() }
        isEnabled = true
    }

    func unregister() throws {
        unregisterCallCount += 1
        if shouldThrow { throw FakeError() }
        isEnabled = false
    }
}

@MainActor
final class LoginItemTests: XCTestCase {
    func test_setEnabled_true_registersAndReturnsTrue() {
        let fake = FakeLoginItemManager()
        let controller = LoginItemController(manager: fake)
        XCTAssertTrue(controller.setEnabled(true))
        XCTAssertEqual(fake.registerCallCount, 1)
        XCTAssertTrue(controller.isEnabled)
    }

    func test_setEnabled_false_unregistersAndReturnsTrue() {
        let fake = FakeLoginItemManager()
        fake.isEnabled = true
        let controller = LoginItemController(manager: fake)
        XCTAssertTrue(controller.setEnabled(false))
        XCTAssertEqual(fake.unregisterCallCount, 1)
        XCTAssertFalse(controller.isEnabled)
    }

    func test_setEnabled_returnsFalseWhenManagerThrows() {
        let fake = FakeLoginItemManager()
        fake.shouldThrow = true
        XCTAssertFalse(LoginItemController(manager: fake).setEnabled(true))
        XCTAssertFalse(LoginItemController(manager: fake).setEnabled(false))
    }

    func test_requiresApproval_defaultsToFalseForManagersThatDontImplementIt() {
        XCTAssertFalse(LoginItemController(manager: FakeLoginItemManager()).requiresApproval)
    }
}
