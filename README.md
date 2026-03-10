# PedalHUD

PedalHUD is a macOS virtual camera for cyclists. It takes a real webcam feed, overlays live ride data such as watts, heart rate, and cadence, and publishes the result as a camera you can select in Slack, Zoom, Google Meet, and other video apps.

## What It Does

- Connects to a Wahoo trainer and heart-rate sensor over Bluetooth.
- Composites ride metrics over a live webcam feed.
- Publishes the composited output through a CoreMediaIO camera extension.
- Lets you preview the feed locally before using it in a call.
- Supports Sparkle in-app updates for installed builds.
- Includes iPhone and Apple Watch relay targets for future/mobile heart-rate workflows.

## Screenshots

Screenshots will live here once they are added:

- app dashboard screenshot
- in-call screenshot from Slack / Meet / Zoom

Planned image paths:

- `docs/images/dashboard.png`
- `docs/images/slack-call.png`

## Requirements

- macOS 15.0 or newer
- A supported webcam
- A Wahoo trainer and/or heart-rate sensor for live ride metrics
- Admin approval on first virtual-camera activation

## Download

Download the latest release from the [Releases page](https://github.com/davidmokos/PedalHUD/releases).

1. Download `PedalHUD.app` from the latest release archive.
2. Move **PedalHUD.app** into `/Applications`.
3. Launch the app from `/Applications`.
4. Use **Activate Virtual Camera** inside the app.

PedalHUD uses [Sparkle](https://sparkle-project.org) for updates, so installed builds can check for new releases directly from the app.

## Quick Start

1. Open **PedalHUD** from `/Applications`.
2. Grant Bluetooth and camera access when macOS prompts you.
3. Pick your physical webcam in the app if needed.
4. Connect your trainer and heart-rate sensor.
5. Click **Activate Virtual Camera**.
6. Approve the system extension in **System Settings > Privacy & Security** if macOS asks.
7. Open Slack, Zoom, Meet, or another video app and choose **PedalHUD Camera** as the camera.

## Troubleshooting

- If virtual camera activation fails, make sure you launched the copy in `/Applications`, not an Xcode-run copy.
- If the camera does not appear in video apps, restart PedalHUD first.
- If macOS shows old extension versions waiting to uninstall, a reboot may be required.
- If you changed extension-rendering code locally, bump the app and extension versions together before re-testing.

## Build From Source

PedalHUD ships with a checked-in Xcode project and a Swift package for shared code.

### Prerequisites

- macOS 15.0+
- Xcode 16.2 or newer
- An Apple Developer account if you want to sign and activate the virtual camera locally

### Local Setup

1. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig`.
2. Fill in your team ID and bundle ID prefix.
3. Open `PedalHUD/PedalHUD.xcodeproj` in Xcode, or build from the command line.

### Test And Build

```bash
swift test

xcodebuild -allowProvisioningUpdates \
  -project PedalHUD/PedalHUD.xcodeproj \
  -scheme PedalHUD \
  -destination 'platform=macOS' \
  -derivedDataPath .build/xcode \
  build
```

To test the virtual camera reliably, install the built app into `/Applications`:

```bash
rsync -a --delete '.build/xcode/Build/Products/Debug/PedalHUD.app/' '/Applications/PedalHUD.app/'
open -n /Applications/PedalHUD.app
```

More detail lives in [docs/xcode-project-setup.md](docs/xcode-project-setup.md).

## Project Layout

- `Sources/PedalHUDCore` — shared models, overlay rendering, app-group helpers, and shared configuration
- `Apps/PedalHUDMac` — the macOS host app
- `Apps/PedalHUDCameraExtension` — the CoreMediaIO virtual camera extension
- `Apps/PedalHUDPhoneRelay` — iPhone relay app
- `Apps/PedalHUDWatchRelay` — watchOS relay app
- `docs/` — architecture, setup, and contributor documentation

## Documentation

- [Architecture](docs/architecture.md)
- [Development setup](docs/xcode-project-setup.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Changelog](CHANGELOG.md)

## Releases

Public releases are signed, notarized, and distributed through GitHub Releases. The repository also includes a local release script for maintainers that generates the DMG, ZIP, and Sparkle `appcast.xml`.

## Contributing

Issues and pull requests are welcome. If you want to contribute code, start with [CONTRIBUTING.md](CONTRIBUTING.md).

## License

PedalHUD is released under the [MIT License](LICENSE).
