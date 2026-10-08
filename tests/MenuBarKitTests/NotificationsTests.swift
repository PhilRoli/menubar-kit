import UserNotifications
import XCTest
@testable import MenuBarKit

final class NotificationsTests: XCTestCase {
    func test_presentationOptionsShowBannerAndSound() {
        XCTAssertEqual(BannerNotificationPresenter.presentationOptions, [.banner, .sound])
    }

    func test_subclassReceivesClickUserInfo() {
        final class Spy: BannerNotificationPresenter {
            var received: [AnyHashable: Any]?
            override func handleClick(userInfo: [AnyHashable: Any]) { received = userInfo }
        }
        let spy = Spy()
        spy.handleClick(userInfo: ["url": "https://example.com"])
        XCTAssertEqual(spy.received?["url"] as? String, "https://example.com")
    }

    func test_defaultHandleClickDoesNothing() {
        BannerNotificationPresenter().handleClick(userInfo: ["url": "https://example.com"])
    }

    func test_notificationCenterConformsToScheduler() {
        XCTAssertTrue(UNUserNotificationCenter.self is NotificationScheduler.Type)
    }
}
