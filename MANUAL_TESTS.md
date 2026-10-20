# Manual validation matrix

Version 1.2.0 is intended for `cordova-ios >= 8.0.0`. Compilation and simulator
results must be recorded separately from physical-device results. Do not infer
physical compatibility from a simulator pass.

## Baseline setup on macOS

Requirements for the validated baseline:

- Node.js 20.17 or newer;
- Cordova CLI 12.0.0;
- `cordova-ios` 8.1.0;
- Xcode 15 or newer and an installed iOS simulator runtime.

```sh
git clone https://github.com/andreszs/cordova-plugin-native-spinner.git
cd cordova-plugin-native-spinner/example
npm install
npm run prepare:ios
npx cordova requirements ios
npx cordova build ios --debug --emulator
npx cordova run ios --emulator
```

Record exact versions before testing:

```sh
node --version
npx cordova --version
npx cordova platform ls
xcodebuild -version
xcrun simctl list devices booted
```

## Simulator cases

Use the buttons in the example app and record pass/fail for each item.

1. **Message and dimming:** show the message case; confirm an indeterminate
   spinner, readable text, and the requested dark overlay.
2. **Touch blocking:** while a fixed overlay is visible, tap where the
   underlying `Touch target` button is located. Its count must not change.
3. **Interaction restoration:** after automatic or explicit `hide()`, tap the
   target and confirm the count increments.
4. **Cancelable:** show the cancelable case and tap the overlay. It must close.
5. **Fixed:** show the blocking case and tap repeatedly. It must remain visible
   until `hide()` runs.
6. **Callback once:** show the callback case and tap repeatedly. The log must
   contain exactly one callback entry; the overlay stays visible until hidden.
7. **Long text:** show the long-message case in portrait and landscape. Text
   must wrap, remain bounded, and be scrollable if it exceeds available height.
8. **Resize:** on iPad, resize a multi-window/split-view scene while visible.
   The overlay must cover the Cordova view and keep its content centered.
9. **Repeated show:** run the update case. Only one overlay/spinner must exist;
   the text and opacity must change.
10. **Repeated hide:** run the repeated-hide case both with and without a
    visible spinner. There must be no crash and normal interaction must remain.
11. **WebView reset:** show a fixed spinner, reload/navigate the WebView, and
    verify that no overlay or callback remains.
12. **Scene lifecycle:** disconnect/close the containing scene while visible,
    then reopen it. No stale overlay, recognizer, or callback may remain.
13. **Warnings:** inspect the Xcode build and runtime logs. Record all warnings;
    there must be no warning caused by deprecated window, screen, orientation,
    or activity-indicator APIs in this plugin.

## Physical-device cases (owner validation pending)

Run cases 1–13 on each intended iPhone/iPad model and iOS version. Also test:

- background/foreground while a fixed spinner is visible;
- an incoming system interruption and return to the app;
- rapid alternating `show()`/`hide()` calls from the WebView;
- VoiceOver focus and Dynamic Type expectations for the host application;
- low-memory or WebView reload behavior if reproducible.

For Android regression on a real device, verify the unchanged title/message,
hardware-back behavior, touch callback, fixed mode, and repeated hide behavior.

## Result record

```text
Commit:
Plugin version:
Node:
Cordova CLI:
cordova-ios:
Xcode:
Simulator/device model:
OS version:
Cases passed:
Cases failed:
Warnings:
Notes:
```

