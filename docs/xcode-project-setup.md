# Xcode Project Setup

The repository contains source folders and resource templates, but no generated Xcode project.

## Targets

Create these targets:

1. `PedalHUDMac`
   - type: macOS App
   - frameworks: `SwiftUI`, `AVFoundation`, `CoreBluetooth`, `SystemExtensions`
   - local package dependency: `PedalHUDCore`

2. `PedalHUDCameraExtension`
   - type: Camera Extension
   - frameworks: `CoreMediaIO`, `CoreVideo`, `CoreImage`, `SwiftUI`
   - local package dependency: `PedalHUDCore`
   - embed in: `PedalHUDMac`

3. `PedalHUDPhoneRelay`
   - type: iOS App
   - frameworks: `SwiftUI`, `WatchConnectivity`
   - local package dependency: `PedalHUDCore`

4. `PedalHUDWatchRelay`
   - type: watchOS App
   - frameworks: `SwiftUI`, `HealthKit`
   - local package dependency: `PedalHUDCore`

## App Group

Replace every placeholder App Group with your real identifier, for example:

```text
group.com.yourcompany.pedalhud
```

The same App Group must be present in:

- the macOS app entitlements
- the camera extension entitlements
- any future XPC helper that shares metric state

## Bundle identifiers

Replace the placeholders before signing:

- `com.example.PedalHUDMac`
- `com.example.PedalHUDCameraExtension`
- `com.example.PedalHUDPhoneRelay`
- `com.example.PedalHUDWatchRelay`

## Recommended initial wiring order

1. Create the macOS app target and attach everything under `Apps/PedalHUDMac/`.
2. Create the camera extension target and attach everything under `Apps/PedalHUDCameraExtension/`.
3. Add the entitlements and App Group to both macOS targets.
4. Confirm the synthetic virtual camera appears in the system camera list.
5. Create the iPhone and watch targets and attach their folders.

## Important implementation gap

The extension currently renders a synthetic frame plus a metrics panel. That is deliberate for the first milestone. Once the virtual camera is stable, replace the synthetic background with a real camera capture source.

