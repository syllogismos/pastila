import AppKit

final class PasteService {
    private let store: ClipboardStore

    init(store: ClipboardStore) {
        self.store = store
    }

    func copyToClipboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // Write self-marker to prevent re-capturing
        pasteboard.setData(Data(), forType: ClipboardMonitor.selfMarkerType)

        switch item.contentType {
        case .text:
            if let text = item.plainText {
                pasteboard.setString(text, forType: .string)
            }

        case .richText:
            if let rtfData = item.richTextData {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            if let text = item.plainText {
                pasteboard.setString(text, forType: .string)
            }

        case .html:
            if let html = item.htmlString {
                pasteboard.setString(html, forType: .html)
            }
            if let text = item.plainText {
                pasteboard.setString(text, forType: .string)
            }

        case .image:
            if let filename = item.imageFilename,
               let data = store.loadImageData(filename: filename) {
                pasteboard.setData(data, forType: .png)
            }

        case .fileURL:
            if let paths = item.fileURLPaths {
                let urls = paths.map { NSURL(fileURLWithPath: $0) }
                pasteboard.writeObjects(urls)
                // Re-add self-marker since writeObjects clears pasteboard types
                pasteboard.setData(Data(), forType: ClipboardMonitor.selfMarkerType)
            }
        }

        // Move this item to top of history
        store.moveToTop(item)
    }
}
