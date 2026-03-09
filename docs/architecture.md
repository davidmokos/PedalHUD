# Architecture

## Goals

- Read live ride metrics, primarily watts and heart rate.
- Composite those metrics over a video feed.
- Expose the result as a selectable virtual camera in Zoom, Meet, Slack, and similar apps.
- Keep the BLE and workout concerns decoupled from the camera pipeline.

## Recommended shape

### 1. macOS host app

Responsibilities:

- onboarding and permissions
- BLE trainer discovery
- preview window and overlay controls
- system-extension activation
- writing the latest metric snapshot into an App Group container

### 2. CoreMediaIO camera extension

Responsibilities:

- publish a virtual camera stream
- read the latest metric snapshot from the App Group container
- composite a HUD over frames
- eventually replace the current synthetic frame generator with a real webcam capture source

### 3. iPhone relay app

Responsibilities:

- receive heart-rate updates from watchOS
- optionally read trainer data when Zwift is already using the same Mac
- forward compact payloads to the Mac host app over the local network

### 4. watchOS app

Responsibilities:

- start an `HKWorkoutSession`
- collect live heart-rate samples
- send updates to the iPhone relay

## Data flow

### Direct trainer path

```text
Wahoo trainer -> macOS app -> App Group metrics file -> camera extension -> virtual camera
```

### Watch relay path

```text
Apple Watch -> iPhone relay -> macOS app -> App Group metrics file -> camera extension -> virtual camera
```

## Why the shared core exists

`PedalHUDCore` is meant to be imported by all Apple targets so they share:

- the live metric model
- transport payload encoding
- overlay configuration
- metric freshness rules
- preview simulation

That avoids each target inventing its own JSON, timestamps, or staleness logic.

## Current scaffold decisions

- The shared state is a file-backed JSON snapshot for simplicity.
- The virtual camera emits synthetic frames first so the CMIO path is isolated from webcam capture complexity.
- The host app uses a simulated metric feed first so the UI and pipeline can be validated before BLE is implemented.

## Next implementation steps

1. Replace `TrainerBluetoothClient` with FTMS / Cycling Power discovery and subscriptions.
2. Replace the synthetic extension frame with real camera capture and pixel-buffer compositing.
3. Add an HTTP or WebSocket receiver in the macOS app for iPhone relay messages.
4. Implement watch workout start/stop and live heart-rate forwarding.
5. Persist overlay placement and visual settings.

