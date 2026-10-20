# Minimal reproduction app

This self-contained Cordova app exercises message wrapping, opacity, blocking,
cancelable mode, one-shot callbacks, repeated `show()`, repeated `hide()`, and
an underlying touch target.

On macOS with Node 20.17 or newer and Xcode 15 or newer:

```sh
cd example
npm install
npm run prepare:ios
npm run run:ios
```

Rotate or resize the simulator while each case is visible. The generated
`platforms`, `plugins`, `node_modules`, and `cordova.js` files are intentionally
ignored.

