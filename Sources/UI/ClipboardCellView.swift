import AppKit

final class ClipboardCellView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("ClipboardCellView")

    private let iconView = NSImageView()
    private let previewLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let sourceLabel = NSTextField(labelWithString: "")
    private let thumbnailView = NSImageView()
    private var thumbnailWidthConstraint: NSLayoutConstraint!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyDown
        iconView.contentTintColor = .secondaryLabelColor
        addSubview(iconView)

        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.font = .systemFont(ofSize: 13)
        previewLabel.textColor = .labelColor
        previewLabel.lineBreakMode = .byTruncatingTail
        previewLabel.maximumNumberOfLines = 1
        previewLabel.cell?.truncatesLastVisibleLine = true
        previewLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(previewLabel)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .tertiaryLabelColor
        addSubview(timeLabel)

        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.font = .systemFont(ofSize: 11)
        sourceLabel.textColor = .tertiaryLabelColor
        addSubview(sourceLabel)

        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.imageScaling = .scaleProportionallyDown
        thumbnailView.wantsLayer = true
        thumbnailView.layer?.cornerRadius = 4
        thumbnailView.layer?.masksToBounds = true
        addSubview(thumbnailView)

        thumbnailWidthConstraint = thumbnailView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            previewLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            previewLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            previewLabel.trailingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: -8),
            previewLabel.bottomAnchor.constraint(lessThanOrEqualTo: sourceLabel.topAnchor, constant: -2),

            sourceLabel.leadingAnchor.constraint(equalTo: previewLabel.leadingAnchor),
            sourceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            timeLabel.leadingAnchor.constraint(equalTo: sourceLabel.trailingAnchor, constant: 8),
            timeLabel.bottomAnchor.constraint(equalTo: sourceLabel.bottomAnchor),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: thumbnailView.leadingAnchor, constant: -8),

            thumbnailView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            thumbnailView.centerYAnchor.constraint(equalTo: centerYAnchor),
            thumbnailView.heightAnchor.constraint(equalToConstant: 32),
            thumbnailWidthConstraint,
        ])
    }

    func configure(with item: ClipboardItem, store: ClipboardStore) {
        iconView.image = item.icon
        previewLabel.stringValue = item.displayText
        timeLabel.stringValue = item.relativeTimeString
        sourceLabel.stringValue = item.sourceApp ?? ""

        if item.contentType == .image, let filename = item.imageFilename,
           let data = store.loadImageData(filename: filename) {
            thumbnailView.image = NSImage(data: data)
            thumbnailWidthConstraint.constant = 32
        } else {
            thumbnailView.image = nil
            thumbnailWidthConstraint.constant = 0
        }
    }
}
