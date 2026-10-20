/* global SpinnerDialog */
'use strict';

document.addEventListener('deviceready', function () {
  var logElement = document.getElementById('log');
  var touchCountElement = document.getElementById('touch-count');
  var touchCount = 0;
  var callbackCount = 0;

  function log(message) {
    logElement.textContent = new Date().toISOString() + ' ' + message + '\n' + logElement.textContent;
  }

  function options(overrides) {
    return Object.assign({
      overlayOpacity: 0.6,
      fontSize: 16,
      errorCallback: function (error) {
        log('ERROR: ' + error);
      }
    }, overrides || {});
  }

  document.getElementById('touch-target').addEventListener('click', function () {
    touchCount += 1;
    touchCountElement.textContent = String(touchCount);
    log('Underlying touch target received touch #' + touchCount);
  });

  document.querySelectorAll('[data-case]').forEach(function (button) {
    button.addEventListener('click', function () {
      switch (button.dataset.case) {
        case 'message':
          SpinnerDialog.show(null, 'Loading account data…', false, options({ overlayOpacity: 0.72 }));
          break;
        case 'cancelable':
          SpinnerDialog.show(null, 'Tap the dark overlay to close', false, options());
          break;
        case 'blocking':
          SpinnerDialog.show(null, 'Touches are blocked for four seconds', true, options());
          setTimeout(function () {
            SpinnerDialog.hide(null, function () { log('Blocking spinner hidden'); });
          }, 4000);
          break;
        case 'callback':
          callbackCount = 0;
          SpinnerDialog.show(null, 'Tap repeatedly. Callback must log once; overlay stays fixed.', function () {
            callbackCount += 1;
            log('Cancel callback count: ' + callbackCount);
          }, options());
          setTimeout(function () { SpinnerDialog.hide(); }, 6000);
          break;
        case 'long':
          SpinnerDialog.show(null,
            'This is a deliberately long message. It should wrap across multiple lines, remain centered, and stay inside the Cordova host view in portrait, landscape, split view, and after a window resize. '.repeat(4),
            false,
            options({ fontSize: 18 }));
          break;
        case 'update':
          SpinnerDialog.show(null, 'First message', true, options({ overlayOpacity: 0.25 }));
          setTimeout(function () {
            SpinnerDialog.show(null, 'Updated message and darker overlay', true, options({ overlayOpacity: 0.75 }));
            setTimeout(function () { SpinnerDialog.hide(); }, 2500);
          }, 750);
          break;
        case 'hide':
          SpinnerDialog.hide();
          SpinnerDialog.hide();
          SpinnerDialog.hide(null, function () { log('Repeated hide() completed safely'); });
          break;
      }
    });
  });

  log('deviceready; platform=' + cordova.platformId);
}, false);

