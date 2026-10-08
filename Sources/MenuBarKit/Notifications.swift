import AppKit
import UserNotifications

public protocol NotificationScheduler {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
}

extension UNUserNotificationCenter: NotificationScheduler {}

/// Shows banners even while the app is active (e.g. Preferences open). Subclasses override `handleClick`
/// to react to a notification being clicked.
open class BannerNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    public static let presentationOptions: UNNotificationPresentationOptions = [.banner, .sound]

    override public init() { super.init() }

    open func handleClick(userInfo: [AnyHashable: Any]) {}

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler:
                                           @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(Self.presentationOptions)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        handleClick(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }
}
