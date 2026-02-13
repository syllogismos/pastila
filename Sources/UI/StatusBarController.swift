import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    var onShowHistory: (() -> Void)?

    /// Screen-coordinate frame of the status bar button, for anchoring the popup.
    var buttonScreenFrame: NSRect {
        guard let button = statusItem.button, let window = button.window else {
            return .zero
        }
        let frameInWindow = button.convert(button.bounds, to: nil)
        return window.convertToScreen(frameInWindow)
    }
    var onClearHistory: (() -> Void)?
    var onQuit: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            onShowHistory?()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Show History", action: #selector(showHistoryAction), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Clear History", action: #selector(clearHistoryAction), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitAction), keyEquivalent: "q")
            .target = self

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Remove menu so left-click works again
        statusItem.menu = nil
    }

    @objc private func showHistoryAction() {
        onShowHistory?()
    }

    @objc private func clearHistoryAction() {
        onClearHistory?()
    }

    @objc private func quitAction() {
        onQuit?()
    }
}
