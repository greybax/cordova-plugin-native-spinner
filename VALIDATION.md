# Validation record for 1.2.0

Date: 2026-10-20

## Completed

| Check | Environment | Result |
| --- | --- | --- |
| Repository tests (`npm test`) | Node 20.17.0, Windows | 9/9 passed |
| Clean Cordova app creation | Cordova CLI 12.0.0 (`cordova-lib` 12.0.2) | Passed |
| Add iOS platform | `cordova-ios` 8.1.0 | Passed |
| Install local plugin | Plugin 1.2.0 | Passed |
| `cordova prepare ios` | Node 20.17.0, Cordova CLI 12.0.0 | Passed |
| Install in Android-only clean app | Cordova CLI 12.0.0, `cordova-android` 15.1.0 | Passed |
| Android regression build | `cordova-android` 15.1.0, Android SDK 36, JDK 17.0.10, Gradle 8.14.2 | Passed; debug APK produced |

The Android native source was not modified. The Android build validates the
shared JavaScript bridge and packaging changes.

## Not performed in this environment

- `xcodebuild` compilation: unavailable because the validation host is Windows;
- iOS simulator launch or visual checks: not performed;
- iOS physical-device deployment or visual checks: not performed;
- Android physical-device deployment: not performed;
- Windows, Windows Phone, and Browser runtime checks: not performed.

`cordova requirements ios` correctly reported that Apple macOS is required,
and the attempted iOS build stopped because `xcodebuild >= 15.0.0` was not
available. No iOS compile, simulator, or physical-device compatibility claim is
made from the successful `cordova prepare ios` result.

Use [`MANUAL_TESTS.md`](MANUAL_TESTS.md) to record macOS simulator and owner-run
physical-device results.
