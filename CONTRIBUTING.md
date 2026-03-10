# Contributing

Thanks for contributing to PedalHUD.

## Before You Start

- Search existing issues and pull requests before opening a new one.
- Prefer small, focused pull requests over large cross-cutting rewrites.
- If you are changing behavior in the virtual camera path, test from `/Applications`, not from an Xcode-run app bundle.

## Development Setup

1. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig`.
2. Set your Apple team ID and bundle ID prefix.
3. Run the test suite:

```bash
swift test
```

4. Build the macOS app:

```bash
xcodebuild -allowProvisioningUpdates \
  -project PedalHUD/PedalHUD.xcodeproj \
  -scheme PedalHUD \
  -destination 'platform=macOS' \
  -derivedDataPath .build/xcode \
  build
```

5. Install the built app into `/Applications` for extension testing:

```bash
rsync -a --delete '.build/xcode/Build/Products/Debug/PedalHUD.app/' '/Applications/PedalHUD.app/'
open -n /Applications/PedalHUD.app
```

## What To Test

At minimum, test the area you changed:

- `swift test` for shared/core changes
- app launch on macOS for host-app changes
- virtual camera activation and selection in a video app for extension changes

If your change touches either of these areas:

- `Apps/PedalHUDCameraExtension`
- `Sources/PedalHUDCore` when it affects rendered output or extension behavior

Then bump both version files together before testing:

- `Apps/PedalHUDMac/Resources/PedalHUD-Info.plist`
- `Apps/PedalHUDCameraExtension/Resources/Info.plist`

## Pull Request Checklist

- Describe the user-visible change clearly.
- Mention how you tested it.
- Update docs if behavior, setup, or release steps changed.
- Include screenshots when the UI changed.
- Avoid committing local-only config, credentials, provisioning profiles, or generated release artifacts.

## Release Notes

Maintainers can create a notarized release locally with:

```bash
./scripts/build-release.sh <version> <build>
```

That command produces:

- a notarized ZIP
- a notarized DMG
- `appcast.xml` for Sparkle
