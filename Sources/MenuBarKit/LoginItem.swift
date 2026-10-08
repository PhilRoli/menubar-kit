import ServiceManagement

public protocol LoginItemManaging {
    var isEnabled: Bool { get }
    var requiresApproval: Bool { get }
    func register() throws
    func unregister() throws
}

public extension LoginItemManaging {
    var requiresApproval: Bool { false }
}

public struct SMAppServiceLoginItemManager: LoginItemManaging {
    public init() {}

    public var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    public var requiresApproval: Bool { SMAppService.mainApp.status == .requiresApproval }
    public func register() throws { try SMAppService.mainApp.register() }
    public func unregister() throws { try SMAppService.mainApp.unregister() }
}

@MainActor
public final class LoginItemController {
    private let manager: LoginItemManaging

    public init(manager: LoginItemManaging = SMAppServiceLoginItemManager()) {
        self.manager = manager
    }

    public var isEnabled: Bool { manager.isEnabled }

    /// True when macOS registered the item but is waiting for the user to approve it in System Settings.
    public var requiresApproval: Bool { manager.requiresApproval }

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try manager.register()
            } else {
                try manager.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}
