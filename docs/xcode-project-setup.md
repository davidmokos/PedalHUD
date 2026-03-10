# Development Setup

PedalHUD includes a checked-in Xcode project and a local Swift package. You do not need to generate the project yourself.

## Prerequisites

- macOS 15.0 or newer
- Xcode 16.2 or newer
- An Apple Developer account if you want to activate the virtual camera locally

## Local Configuration

Create `Config/Local.xcconfig` from the example file:

```bash
cp Config/Local.xcconfig.example Config/Local.xcconfig
```

Set:

- `DEVELOPMENT_TEAM`
- `BUNDLE_ID_PREFIX`

The shared app group is derived automatically from the bundle ID prefix:

```text
group.$(BUNDLE_ID_PREFIX)
```

## Build

Run tests first:

```bash
swift test
```

Build the macOS app:

```bash
xcodebuild -allowProvisioningUpdates \
  -project PedalHUD/PedalHUD.xcodeproj \
  -scheme PedalHUD \
  -destination 'platform=macOS' \
  -derivedDataPath .build/xcode \
  build
```

The built app will be here:

```text
.build/xcode/Build/Products/Debug/PedalHUD.app
```

## Test The Virtual Camera

Use the installed app in `/Applications`, not the Xcode-run copy:

```bash
rsync -a --delete '.build/xcode/Build/Products/Debug/PedalHUD.app/' '/Applications/PedalHUD.app/'
open -n /Applications/PedalHUD.app
```

Then test:

1. **Activate Virtual Camera**
2. macOS system-extension approval
3. camera selection in Photo Booth / Slack / Zoom / Meet

## Version Bumps For Extension Changes

If you change either of these:

- `Apps/PedalHUDCameraExtension`
- `Sources/PedalHUDCore` when the change affects rendered output or extension behavior

Then bump both version files together before testing:

- `Apps/PedalHUDMac/Resources/PedalHUD-Info.plist`
- `Apps/PedalHUDCameraExtension/Resources/Info.plist`

This avoids macOS continuing to serve an older extension build.

## Releasing

The local maintainer release path is:

```bash
./scripts/build-release.sh <version> <build>
```

That script archives, re-signs, notarizes, staples, creates the DMG/ZIP, and generates `appcast.xml` for Sparkle.
