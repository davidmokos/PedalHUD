# Architecture

PedalHUD has one job: take a real webcam feed, add live cycling metrics, and publish the result as a virtual camera that video apps can consume.

## High-Level Components

### `PedalHUD` macOS host app

Responsibilities:

- request camera and Bluetooth permissions
- discover trainers and heart-rate peripherals
- let the user preview the webcam and choose a preferred camera
- manage overlay configuration
- activate the system extension
- write live metric snapshots into the shared App Group container

### `PedalHUDCameraExtension` CoreMediaIO extension

Responsibilities:

- capture frames from the selected physical webcam
- read the latest metrics from the App Group container
- composite the PedalHUD overlay over video frames
- publish the resulting stream as `PedalHUD Camera`

### `PedalHUDCore` shared package

Responsibilities:

- shared live-metric types
- overlay rendering models and shared view code
- app-group identifiers and file-backed stores
- camera-selection and overlay-configuration persistence

### `PedalHUDPhoneRelay` iPhone app

Responsibilities:

- receive heart-rate data from watchOS
- forward relay data toward the Mac host app

### `PedalHUDWatchRelay` watchOS app

Responsibilities:

- run an `HKWorkoutSession`
- collect live heart-rate data
- forward samples to the iPhone relay

## Data Flow

### Direct Bluetooth path

```text
Trainer / HR sensor -> macOS host app -> App Group metrics file -> camera extension -> virtual camera
```

### Watch relay path

```text
Apple Watch -> iPhone relay -> macOS host app -> App Group metrics file -> camera extension -> virtual camera
```

## Key Design Choices

- **App Group file-backed IPC** keeps the host app and camera extension loosely coupled.
- **CoreMediaIO camera extension** exposes a system-level virtual camera that works across apps.
- **Shared Swift package** keeps overlay logic, metric models, and persistence rules consistent across targets.
- **Sparkle updates** are handled in the macOS app so installed builds can self-update.

## Operational Constraints

- The camera extension must be tested from an app bundle installed in `/Applications`.
- Extension-facing behavior changes should be paired with a version bump in both macOS and extension `Info.plist` files.
- macOS may keep old extension versions staged until restart or reboot.

## Current State

- The macOS app can preview a physical camera.
- The camera extension captures from a physical webcam and publishes a composited virtual camera feed.
- Trainer and heart-rate data flow through the shared metrics store into the overlay.
- Sparkle update metadata is published through GitHub Releases appcast assets.

## Future Improvements

1. Broaden BLE device support and recovery logic.
2. Improve overlay customization and persistence.
3. Finish and harden the phone/watch relay path.
4. Expand automated testing around metrics freshness and rendering behavior.
