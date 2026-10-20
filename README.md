# cordova-plugin-native-spinner

Cordova plugin for showing a native indeterminate spinner. This fork modernizes
the iOS implementation for the `UIScene` architecture used by `cordova-ios` 8
while preserving the public JavaScript API and the existing Android code.

## Installation

Install the maintained fork directly from GitHub:

```sh
cordova plugin add https://github.com/andreszs/cordova-plugin-native-spinner.git
cordova prepare
```

Pin a tag or commit in production builds:

```sh
cordova plugin add https://github.com/andreszs/cordova-plugin-native-spinner.git#v1.2.0
```

## Compatibility

| Platform | Status | Requirements / validation |
| --- | --- | --- |
| iOS | Supported | `cordova-ios >= 8.0.0`; iOS 13+ as required by Cordova iOS 8 |
| Android | Existing implementation retained | No Java changes in 1.2.0 |
| Browser | Existing implementation retained | Not changed in 1.2.0 |
| Windows 10 | Legacy implementation retained | Not changed or revalidated in 1.2.0 |
| Windows Phone 8.1 | Legacy implementation retained | Not changed or revalidated in 1.2.0 |

The iOS 1.2.0 development baseline is Node 20.17+, Cordova CLI 12, `cordova-ios
8.1.0`, and Xcode 15+. iOS builds and the simulator require macOS. Physical
device compatibility is not claimed until the manual device matrix in
[`MANUAL_TESTS.md`](MANUAL_TESTS.md) has been completed.

## API

The public API is unchanged:

```js
SpinnerDialog.show(title, message, cancelCallback, options);
SpinnerDialog.hide();
```

### `SpinnerDialog.show(title, message, cancelCallback, options)`

- `title`: title on Android; used as the iOS message when `message` is absent.
- `message`: arbitrary text. The iOS view supports wrapping and scrolls very
  long content instead of drawing outside the host view.
- `cancelCallback`:
  - omitted or `false`: the overlay is cancelable by tapping it;
  - `true`: the overlay is fixed and must be hidden explicitly;
  - function: preserves the legacy fixed behavior and invokes the function at
    most once when the overlay is tapped. Call `hide()` explicitly afterward.
- `options`: iOS-only appearance and error options:
  - `overlayOpacity` from `0` to `1` (default `0.35`);
  - `textColorRed`, `textColorGreen`, `textColorBlue` from `0` to `1`;
  - `fontSize` from `8` to `30` (default `16`);
  - `errorCallback(error)` receives native setup errors, including a missing
    Cordova host view or detached scene.

Values are clamped natively. An explicit zero remains valid.

### `SpinnerDialog.hide()`

Stops and removes the current overlay. Calling `hide()` when no spinner is
visible, or calling it repeatedly, is safe.

## Examples

Message with the default cancelable behavior:

```js
SpinnerDialog.show(null, 'Loading account data…');
```

Blocking overlay with stronger dimming:

```js
SpinnerDialog.show(null, 'Please wait', true, {
  overlayOpacity: 0.7,
  fontSize: 16,
  errorCallback: function (error) {
    console.error(error);
  }
});
```

Fixed overlay with a one-shot tap callback:

```js
SpinnerDialog.show(null, 'Tap to request cancellation', function () {
  cancelCurrentOperation();
  SpinnerDialog.hide();
});
```

Update the visible message and options without stacking overlays:

```js
SpinnerDialog.show(null, 'Step 1 of 2', true, { overlayOpacity: 0.35 });
SpinnerDialog.show(null, 'Step 2 of 2', true, { overlayOpacity: 0.65 });
```

Restore interaction:

```js
SpinnerDialog.hide();
```

## iOS implementation notes

The overlay is attached to `self.viewController.view`, which is the view owned
by the current Cordova controller and scene. The implementation does not query
the application delegate, `keyWindow`, global screen bounds, or status-bar
orientation. UI work is serialized on the main queue; the overlay uses the
host view's live bounds and flexible width/height autoresizing. It is also
removed on WebView reset, plugin disposal, and scene disconnection.

## Reproducible test app

[`example`](example) contains a minimal Cordova app for all supported spinner
variants. [`MANUAL_TESTS.md`](MANUAL_TESTS.md) contains simulator and physical
device cases and the required result-recording template.

Run repository checks with:

```sh
npm test
```

## License and attribution

MIT. Based on
[`greybax/cordova-plugin-native-spinner`](https://github.com/greybax/cordova-plugin-native-spinner)
and the earlier Paldom/SpinnerDialog work.
