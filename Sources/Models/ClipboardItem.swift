import AppKit

enum ClipboardContentType: String, Codable {
    case text
    case richText
    case html
    case image
    case fileURL
}

struct ClipboardItem: Codable, Identifiable {
    let id: UUID
    let contentType: ClipboardContentType
    let timestamp: Date
    let sourceApp: String?
    let plainText: String?
    let richTextData: Data?
    let htmlString: String?
    let imageFilename: String?
    let fileURLPaths: [String]?

    var searchText: String {
        if let text = plainText {
            return text.lowercased()
        }
        if let paths = fileURLPaths {
            return paths.joined(separator: " ").lowercased()
        }
        if contentType == .image {
            return "image"
        }
        return ""
    }

    var displayText: String {
        if let text = plainText {
            // Collapse all whitespace/newlines into single spaces for one-line preview
            let collapsed = text.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            if collapsed.count > 200 {
                return String(collapsed.prefix(200)) + "..."
            }
            return collapsed
        }
        if let paths = fileURLPaths {
            return paths.map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
        }
        if contentType == .image {
            return "Image"
        }
        return ""
    }

    var icon: NSImage {
        let name: String
        switch contentType {
        case .text:
            name = "doc.plaintext"
        case .richText:
            name = "doc.richtext"
        case .html:
            name = "globe"
        case .image:
            name = "photo"
        case .fileURL:
            name = "doc.on.doc"
        }
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!
    }

    var relativeTimeString: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    var absoluteTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var contentTypeLabel: String {
        switch contentType {
        case .text: return "Plain Text"
        case .richText: return "Rich Text"
        case .html: return "HTML"
        case .image: return "Image"
        case .fileURL: return "File"
        }
    }

    var fullPreviewText: String {
        if let text = plainText {
            if text.count > 1000 {
                return String(text.prefix(1000)) + "..."
            }
            return text
        }
        if let paths = fileURLPaths {
            return paths.joined(separator: "\n")
        }
        if contentType == .image {
            return "Image"
        }
        return ""
    }
}
