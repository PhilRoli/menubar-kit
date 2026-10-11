import AppKit

public extension NSMenuItem {
    /// A menu item that sends `action` to `target` (menu items default to the responder chain otherwise).
    static func item(_ title: String, action: Selector, key: String = "", target: AnyObject) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = target
        return item
    }

    /// Enabled but action-less, so attributed-title colours aren't dimmed the way disabled items are.
    static func info(_ title: NSAttributedString, indent: Int = 0) -> NSMenuItem {
        let item = NSMenuItem(title: title.string, action: nil, keyEquivalent: "")
        item.attributedTitle = title
        item.indentationLevel = indent
        item.isEnabled = true
        return item
    }
}
