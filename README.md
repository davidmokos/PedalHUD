# PedalHUD

A macOS virtual camera that overlays live cycling metrics — watts, heart rate, cadence — directly onto your webcam feed. Use it in Zoom, Google Meet, Slack, or any app that supports camera selection.

## How it works

PedalHUD connects to your Wahoo trainer and heart-rate sensor via Bluetooth, composites real-time metrics over your webcam video, and exposes the result as a system-level virtual camera through a CoreMediaIO camera extension.

## Download

Grab the latest release from the [Releases page](https://github.com/davidmokos/PedalHUD/releases). Download the ZIP, unzip it, and drag **PedalHUD.app** to your Applications folder. The app checks for updates automatically via Sparkle.

## Usage

1. Launch **PedalHUD** from Applications.
2. Grant Bluetooth and camera permissions when prompted.
3. Connect your Wahoo trainer — it will appear in the device list automatically.
4. Click **Activate Virtual Camera** to install the system extension (requires admin approval on first use).
5. Open Zoom, Google Meet, or any video app and select **PedalHUD Camera** from the camera list.

Your live watts, heart rate, and cadence will appear as an overlay on your webcam feed.

## Building from source

### Prerequisites

- macOS 15.0+
- Xcode 16.2+

### Build

1. Clone the repository.
2. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and fill in your Apple Team ID and bundle ID prefix.
3. Open `PedalHUD/PedalHUD.xcodeproj` in Xcode.
4. Build and run the **PedalHUD** scheme.

### Run tests

```bash
swift test
```

## Architecture

The project is split into:

- **PedalHUDCore** — shared Swift package with metric models, overlay rendering, and file-backed IPC.
- **PedalHUD (macOS app)** — host app for BLE discovery, overlay controls, and system extension activation.
- **PedalHUDCameraExtension** — CoreMediaIO camera extension that reads metrics and composites the HUD over webcam frames.
- **PedalHUDPhoneRelay** — iOS app that relays heart-rate data from the watch to the Mac.
- **PedalHUDWatchRelay** — watchOS app that streams live heart rate via `HKWorkoutSession`.

See [docs/architecture.md](docs/architecture.md) for the full data flow.

## Releases

Tagged releases are built, signed, notarized, and published automatically via GitHub Actions. The app includes [Sparkle](https://sparkle-project.org) for automatic updates — once installed, you'll receive new versions without needing to visit GitHub again.

## License

MIT
