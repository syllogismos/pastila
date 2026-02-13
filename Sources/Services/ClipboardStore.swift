import Foundation
import AppKit

final class ClipboardStore {
    private(set) var items: [ClipboardItem] = []
    private let maxItems = 100
    private let saveQueue = DispatchQueue(label: "com.anil.pastila.save", qos: .utility)
    private let supportDir: URL
    private let imagesDir: URL
    private let historyFile: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        supportDir = appSupport.appendingPathComponent("Pastila")
        imagesDir = supportDir.appendingPathComponent("images")
        historyFile = supportDir.appendingPathComponent("history.json")

        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        load()
    }

    func add(_ item: ClipboardItem) {
        // Deduplication: remove any existing duplicate anywhere in history
        if let existingIndex = findDuplicate(of: item) {
            let existing = items.remove(at: existingIndex)
            // If the duplicate was already at the top, just update timestamp by replacing
            if existingIndex == 0 {
                items.insert(existing, at: 0)
                return
            }
            // Clean up old image if the new item has its own
            if existing.imageFilename != nil && existing.imageFilename != item.imageFilename {
                cleanupImageFile(for: existing)
            }
        }

        items.insert(item, at: 0)

        // Evict old items
        while items.count > maxItems {
            let evicted = items.removeLast()
            cleanupImageFile(for: evicted)
        }

        scheduleSave()
    }

    /// Move an existing item to the top of history (used when user selects from history).
    func moveToTop(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        if index == 0 { return } // already at top
        let moved = items.remove(at: index)
        items.insert(moved, at: 0)
        scheduleSave()
    }

    func item(at index: Int) -> ClipboardItem? {
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }

    private func findDuplicate(of item: ClipboardItem) -> Int? {
        items.firstIndex { existing in
            guard existing.contentType == item.contentType else { return false }
            switch item.contentType {
            case .text, .richText, .html:
                return existing.plainText == item.plainText && item.plainText != nil
            case .fileURL:
                return existing.fileURLPaths == item.fileURLPaths
            case .image:
                return false // images are always unique
            }
        }
    }

    func clearAll() {
        for item in items {
            cleanupImageFile(for: item)
        }
        items.removeAll()
        scheduleSave()
    }

    func saveImageData(_ data: Data) -> String {
        let filename = UUID().uuidString + ".png"
        let url = imagesDir.appendingPathComponent(filename)
        try? data.write(to: url)
        return filename
    }

    func loadImageData(filename: String) -> Data? {
        let url = imagesDir.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    // MARK: - Private

    private func cleanupImageFile(for item: ClipboardItem) {
        guard let filename = item.imageFilename else { return }
        let url = imagesDir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    private func scheduleSave() {
        let itemsCopy = items
        let file = historyFile
        saveQueue.async {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(itemsCopy)
                try data.write(to: file, options: .atomic)
            } catch {
                NSLog("ClipboardStore: save failed: \(error)")
            }
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: historyFile.path) else { return }
        do {
            let data = try Data(contentsOf: historyFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            items = try decoder.decode([ClipboardItem].self, from: data)
        } catch {
            NSLog("ClipboardStore: load failed: \(error)")
        }
    }
}
