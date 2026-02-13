import AppKit

final class PopupPanel: NSPanel {
    private static let panelWidth: CGFloat = 340
    private static let panelHeight: CGFloat = 420

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .popUpMenu
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = true
        animationBehavior = .utilityWindow
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight))
        visualEffect.material = .menu
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10
        visualEffect.layer?.masksToBounds = true
        contentView = visualEffect
    }

    override var canBecomeKey: Bool { true }

    /// Position the panel directly below the given status item button frame (in screen coordinates).
    func show(relativeTo buttonFrame: NSRect) {
        let width = Self.panelWidth
        let height = Self.panelHeight

        // Center horizontally on the button, drop below the menu bar
        let x = buttonFrame.midX - width / 2
        let y = buttonFrame.minY - height - 4

        // Clamp to screen edges
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let clampedX = max(screenFrame.minX + 4, min(x, screenFrame.maxX - width - 4))

        setFrame(NSRect(x: clampedX, y: y, width: width, height: height), display: true)
        makeKeyAndOrderFront(nil)
    }
}
