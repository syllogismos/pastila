import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var clipboardStore: ClipboardStore!
    private var clipboardMonitor: ClipboardMonitor!
    private var hotkeyManager: HotkeyManager!
    private var pasteService: PasteService!
    private var popupPanel: PopupPanel!
    private var popupViewController: PopupViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services
        clipboardStore = ClipboardStore()
        clipboardMonitor = ClipboardMonitor(store: clipboardStore)
        pasteService = PasteService(store: clipboardStore)

        // Initialize UI
        statusBarController = StatusBarController()
        statusBarController.onShowHistory = { [weak self] in self?.togglePopup() }
        statusBarController.onClearHistory = { [weak self] in self?.clearHistory() }
        statusBarController.onQuit = { NSApp.terminate(nil) }

        // Setup popup
        popupPanel = PopupPanel()
        popupViewController = PopupViewController(store: clipboardStore, pasteService: pasteService)
        popupViewController.onDismiss = { [weak self] in self?.hidePopup() }

        // Embed VC view inside the visual effect content view (not contentViewController,
        // which would replace the visual effect background)
        let vcView = popupViewController.view
        vcView.translatesAutoresizingMaskIntoConstraints = false
        popupPanel.contentView!.addSubview(vcView)
        NSLayoutConstraint.activate([
            vcView.topAnchor.constraint(equalTo: popupPanel.contentView!.topAnchor),
            vcView.bottomAnchor.constraint(equalTo: popupPanel.contentView!.bottomAnchor),
            vcView.leadingAnchor.constraint(equalTo: popupPanel.contentView!.leadingAnchor),
            vcView.trailingAnchor.constraint(equalTo: popupPanel.contentView!.trailingAnchor),
        ])

        // Register hotkey
        hotkeyManager = HotkeyManager()
        hotkeyManager.onHotkey = { [weak self] in self?.togglePopup() }
        hotkeyManager.register()

        // Start monitoring
        clipboardMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotkeyManager.unregister()
    }

    private func togglePopup() {
        if popupPanel.isVisible {
            hidePopup()
        } else {
            showPopup()
        }
    }

    private func showPopup() {
        NSApp.activate(ignoringOtherApps: true)
        popupPanel.show(relativeTo: statusBarController.buttonScreenFrame)
        popupViewController.activate()
    }

    private func hidePopup() {
        popupPanel.orderOut(nil)
    }

    private func clearHistory() {
        clipboardStore.clearAll()
    }
}
