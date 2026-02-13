# Pastila

A lightweight macOS menu bar app for clipboard history. Fast, native, and zero dependencies.

**[Download Pastila](https://github.com/syllogismos/pastila/releases/latest/download/Pastila.app.zip)** (63 KB)

## Features

- Tracks **text, rich text, HTML, images, and file URLs**
- Searchable popup with real-time filtering
- Global hotkey: **Cmd+Shift+C** to open
- Hover any item to preview full content with metadata
- Click or press Enter to copy back to clipboard
- Smart deduplication — no repeated entries
- Persists history across restarts (up to 100 items)
- Menu bar only — no Dock icon, no clutter
- **63 KB** app size, near-zero CPU usage

## Install

### Download

1. Download [`Pastila.app.zip`](https://github.com/syllogismos/pastila/releases/latest/download/Pastila.app.zip)
2. Unzip and drag **Pastila.app** to `/Applications`
3. Open it — a clipboard icon appears in the menu bar

> On first launch, macOS may warn about an unidentified developer. Right-click the app → **Open** → click **Open** in the dialog.

### Build from source

Requires Xcode command line tools (`xcode-select --install`).

```bash
git clone https://github.com/syllogismos/pastila.git
cd pastila
make
open build/Pastila.app
```

## Usage

| Action | How |
|--------|-----|
| Open history | Click menu bar icon or **Cmd+Shift+C** |
| Search | Start typing |
| Navigate | **Up** / **Down** arrow keys |
| Copy item | **Enter** or click a row |
| Preview details | Hover over a row |
| Close | **Escape** or click outside |
| Clear history | Right-click menu bar icon → Clear History |
| Quit | Right-click menu bar icon → Quit |

## How it works

Pure Swift + AppKit, compiled with `swiftc` — no Xcode project needed.

- **Monitoring** — polls `NSPasteboard.general.changeCount` every 0.5s (near-zero CPU)
- **Global hotkey** — Carbon `RegisterEventHotKey` (no Accessibility permissions needed)
- **Persistence** — JSON at `~/Library/Application Support/Pastila/`
- **UI** — `NSPanel` + `NSVisualEffectView` for native translucent menu appearance

## Requirements

macOS 13.0 (Ventura) or later.

## License

MIT
