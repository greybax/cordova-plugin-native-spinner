# Changelog

## 1.2.0 - 2026-10-20

### Changed

- Replaced application-delegate and global-screen window lookup on iOS with the
  view owned by the current Cordova controller.
- Added `UIScene` attachment validation and cleanup when the attached scene is
  disconnected.
- Serialized every iOS view mutation on the main queue.
- Reused a single overlay across consecutive `show()` calls and updated its
  message, colors, font size, opacity, and fixed/cancelable state in place.
- Made the overlay follow the host view's live bounds during rotation, split
  view, and other size changes.
- Added multiline and bounded long-message layout.
- Made repeated `hide()` calls safe and added cleanup for Cordova WebView reset
  and plugin disposal.
- Made the tap/cancel callback one-shot and explicitly released superseded or
  hidden callbacks.
- Added an iOS `options.errorCallback` for native host-view errors.
- Preserved explicit zero values in iOS appearance options.
- Increased the default iOS message size to 16 pt and rendered it opaque with
  semibold weight for legibility over the dimmed content.

### Added

- Node-based API and iOS source regression tests.
- A minimal Cordova reproduction app and a manual simulator/device checklist.

### Unchanged

- Android native implementation and appearance.
- Public JavaScript method names and argument order.

