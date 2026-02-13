import AppKit

final class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private let store: ClipboardStore
    static let selfMarkerType = NSPasteboard.PasteboardType("com.anil.pastila.self")

    init(store: ClipboardStore) {
        self.store = store
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Skip self-paste
        if pasteboard.data(forType: ClipboardMonitor.selfMarkerType) != nil {
            return
        }

        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        if let item = captureItem(sourceApp: sourceApp) {
            store.add(item)
        }
    }

    private func captureItem(sourceApp: String?) -> ClipboardItem? {
        // Priority: fileURL > image > rtf > html > text

        // File URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], !urls.isEmpty {
            let paths = urls.map { $0.path }
            return ClipboardItem(
                id: UUID(),
                contentType: .fileURL,
                timestamp: Date(),
                sourceApp: sourceApp,
                plainText: nil,
                richTextData: nil,
                htmlString: nil,
                imageFilename: nil,
                fileURLPaths: paths
            )
        }

        // Image
        if let tiffData = pasteboard.data(forType: .tiff),
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            let filename = store.saveImageData(pngData)
            return ClipboardItem(
                id: UUID(),
                contentType: .image,
                timestamp: Date(),
                sourceApp: sourceApp,
                plainText: nil,
                richTextData: nil,
                htmlString: nil,
                imageFilename: filename,
                fileURLPaths: nil
            )
        }

        // Rich text
        if let rtfData = pasteboard.data(forType: .rtf) {
            let plainText = pasteboard.string(forType: .string)
            return ClipboardItem(
                id: UUID(),
                contentType: .richText,
                timestamp: Date(),
                sourceApp: sourceApp,
                plainText: plainText,
                richTextData: rtfData,
                htmlString: nil,
                imageFilename: nil,
                fileURLPaths: nil
            )
        }

        // HTML
        if let htmlString = pasteboard.string(forType: .html) {
            let plainText = pasteboard.string(forType: .string)
            return ClipboardItem(
                id: UUID(),
                contentType: .html,
                timestamp: Date(),
                sourceApp: sourceApp,
                plainText: plainText,
                richTextData: nil,
                htmlString: htmlString,
                imageFilename: nil,
                fileURLPaths: nil
            )
        }

        // Plain text
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return ClipboardItem(
                id: UUID(),
                contentType: .text,
                timestamp: Date(),
                sourceApp: sourceApp,
                plainText: text,
                richTextData: nil,
                htmlString: nil,
                imageFilename: nil,
                fileURLPaths: nil
            )
        }

        return nil
    }
}
