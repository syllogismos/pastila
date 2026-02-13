import AppKit

final class PopupViewController: NSViewController {
    private let searchField = NSTextField()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let store: ClipboardStore
    private let pasteService: PasteService
    private var filteredItems: [ClipboardItem] = []
    private var searchText = ""

    // Hover popover
    private var hoverPopover: NSPopover?
    private var hoverRow: Int = -1
    private var hoverTimer: Timer?
    private var trackingArea: NSTrackingArea?

    var onDismiss: (() -> Void)?

    init(store: ClipboardStore, pasteService: PasteService) {
        self.store = store
        self.pasteService = pasteService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 420))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchField()
        setupTableView()
        reloadData()
    }

    func activate() {
        searchField.stringValue = ""
        searchText = ""
        dismissHoverPopover()
        reloadData()
        view.window?.makeFirstResponder(searchField)
    }

    private func setupSearchField() {
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Search clipboard history..."
        searchField.font = .systemFont(ofSize: 16)
        searchField.focusRingType = .none
        searchField.isBordered = false
        searchField.backgroundColor = .clear
        searchField.delegate = self
        view.addSubview(searchField)

        let separator = NSBox()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.boxType = .separator
        view.addSubview(separator)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            separator.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupTableView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        view.addSubview(scrollView)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
        column.width = 320
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.rowHeight = 44
        tableView.style = .plain
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        tableView.dataSource = self
        tableView.delegate = self
        // Single click to paste
        tableView.action = #selector(tableClicked)
        tableView.target = self

        scrollView.documentView = tableView

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        // Keep tracking area in sync with the scroll view's clip view
        if let old = trackingArea {
            scrollView.contentView.removeTrackingArea(old)
        }
        let ta = NSTrackingArea(
            rect: scrollView.contentView.bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        scrollView.contentView.addTrackingArea(ta)
        trackingArea = ta
    }

    // MARK: - Hover

    override func mouseMoved(with event: NSEvent) {
        let locationInTable = tableView.convert(event.locationInWindow, from: nil)
        let row = tableView.row(at: locationInTable)
        if row >= 0 && row < filteredItems.count && row != hoverRow {
            hoverRow = row
            hoverTimer?.invalidate()
            hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
                self?.showHoverPopover(for: row)
            }
        } else if row < 0 || row >= filteredItems.count {
            dismissHoverPopover()
        }
    }

    override func mouseExited(with event: NSEvent) {
        dismissHoverPopover()
    }

    private func showHoverPopover(for row: Int) {
        guard row >= 0 && row < filteredItems.count else { return }
        dismissHoverPopover()

        let item = filteredItems[row]
        let popover = NSPopover()
        popover.behavior = .semitransient
        popover.animates = true

        let vc = DetailPopoverViewController(item: item, store: store)
        popover.contentViewController = vc

        let rowRect = tableView.rect(ofRow: row)
        popover.show(relativeTo: rowRect, of: tableView, preferredEdge: .maxX)
        hoverPopover = popover
    }

    private func dismissHoverPopover() {
        hoverTimer?.invalidate()
        hoverTimer = nil
        hoverPopover?.performClose(nil)
        hoverPopover = nil
        hoverRow = -1
    }

    // MARK: - Data

    private func reloadData() {
        if searchText.isEmpty {
            filteredItems = store.items
        } else {
            let query = searchText.lowercased()
            filteredItems = store.items.filter { $0.searchText.contains(query) }
        }
        tableView.reloadData()
        if !filteredItems.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    private func copySelectedItem() {
        let row = tableView.selectedRow
        guard row >= 0 && row < filteredItems.count else { return }
        let item = filteredItems[row]
        dismissHoverPopover()
        pasteService.copyToClipboard(item: item)
        onDismiss?()
    }

    @objc private func tableClicked() {
        let row = tableView.clickedRow
        guard row >= 0 && row < filteredItems.count else { return }
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        copySelectedItem()
    }
}

// MARK: - NSTextFieldDelegate

extension PopupViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        searchText = searchField.stringValue
        dismissHoverPopover()
        reloadData()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            let next = min(tableView.selectedRow + 1, filteredItems.count - 1)
            tableView.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
            tableView.scrollRowToVisible(next)
            return true
        }
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            let prev = max(tableView.selectedRow - 1, 0)
            tableView.selectRowIndexes(IndexSet(integer: prev), byExtendingSelection: false)
            tableView.scrollRowToVisible(prev)
            return true
        }
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            copySelectedItem()
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            dismissHoverPopover()
            onDismiss?()
            return true
        }
        return false
    }
}

// MARK: - NSTableViewDataSource

extension PopupViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        filteredItems.count
    }
}

// MARK: - NSTableViewDelegate

extension PopupViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellView = tableView.makeView(withIdentifier: ClipboardCellView.identifier, owner: nil) as? ClipboardCellView
        if cellView == nil {
            cellView = ClipboardCellView(frame: NSRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
            cellView?.identifier = ClipboardCellView.identifier
        }
        if row < filteredItems.count {
            cellView?.configure(with: filteredItems[row], store: store)
        }
        return cellView
    }
}

// MARK: - Detail Popover

final class DetailPopoverViewController: NSViewController {
    private let item: ClipboardItem
    private let store: ClipboardStore

    init(item: ClipboardItem, store: ClipboardStore) {
        self.item = item
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func loadView() {
        let width: CGFloat = 300
        let contentWidth = width - 24 // 12pt padding each side

        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 100))

        // Header: type + app + time
        let headerLabel = NSTextField(labelWithString: "")
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.font = .systemFont(ofSize: 11, weight: .medium)
        headerLabel.textColor = .secondaryLabelColor
        var headerParts = [item.contentTypeLabel]
        if let app = item.sourceApp, !app.isEmpty {
            headerParts.append(app)
        }
        headerParts.append(item.absoluteTimeString)
        headerLabel.stringValue = headerParts.joined(separator: "  \u{2022}  ")
        headerLabel.lineBreakMode = .byTruncatingTail
        container.addSubview(headerLabel)

        // Separator
        let separator = NSBox()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.boxType = .separator
        container.addSubview(separator)

        var constraints: [NSLayoutConstraint] = [
            headerLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            headerLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            headerLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),

            separator.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
        ]

        var lastAnchor = separator.bottomAnchor

        if item.contentType == .image, let filename = item.imageFilename,
           let data = store.loadImageData(filename: filename) {
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = NSImage(data: data)
            imageView.imageScaling = .scaleProportionallyDown
            imageView.wantsLayer = true
            imageView.layer?.cornerRadius = 6
            imageView.layer?.masksToBounds = true
            container.addSubview(imageView)

            constraints += [
                imageView.topAnchor.constraint(equalTo: lastAnchor, constant: 10),
                imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
                imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 200),
            ]
            lastAnchor = imageView.bottomAnchor
        }

        // Always show text content if available (even for images with alt text)
        let previewText = item.fullPreviewText
        if !previewText.isEmpty && item.contentType != .image {
            // Calculate text height, capped at 200pt
            let font = NSFont.systemFont(ofSize: 12)
            let textStorage = NSTextStorage(string: previewText, attributes: [.font: font])
            let layoutContainer = NSTextContainer(containerSize: NSSize(width: contentWidth - 8, height: .greatestFiniteMagnitude))
            layoutContainer.lineFragmentPadding = 4
            let layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(layoutContainer)
            textStorage.addLayoutManager(layoutManager)
            layoutManager.ensureLayout(for: layoutContainer)
            let textHeight = min(ceil(layoutManager.usedRect(for: layoutContainer).height) + 8, 200)

            // Build the scroll view + text view with proper frame-based sizing
            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: textHeight))
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.hasVerticalScroller = true
            scrollView.drawsBackground = false
            scrollView.borderType = .noBorder

            let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: textHeight))
            textView.isEditable = false
            textView.isSelectable = true
            textView.drawsBackground = false
            textView.font = font
            textView.textColor = .labelColor
            textView.textContainer?.containerSize = NSSize(width: contentWidth - 8, height: .greatestFiniteMagnitude)
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.lineFragmentPadding = 4
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textView.autoresizingMask = [.width]
            textView.maxSize = NSSize(width: contentWidth, height: .greatestFiniteMagnitude)
            textView.minSize = NSSize(width: contentWidth, height: 0)
            textView.string = previewText

            scrollView.documentView = textView
            container.addSubview(scrollView)

            constraints += [
                scrollView.topAnchor.constraint(equalTo: lastAnchor, constant: 8),
                scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
                scrollView.heightAnchor.constraint(equalToConstant: textHeight),
            ]
            lastAnchor = scrollView.bottomAnchor
        }

        constraints += [
            lastAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            container.widthAnchor.constraint(equalToConstant: width),
        ]

        NSLayoutConstraint.activate(constraints)

        self.view = container
    }
}
