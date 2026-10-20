var exec = require('cordova/exec');

function optionOrDefault(options, name, defaultValue) {
  return options[name] === undefined || options[name] === null
    ? defaultValue
    : options[name];
}

function isIos() {
  if (typeof cordova !== 'undefined' && cordova.platformId) {
    return cordova.platformId === 'ios';
  }

  return typeof navigator !== 'undefined' && /iPad|iPhone|iPod/i.test(navigator.userAgent);
}

module.exports = {
  show: function (title, message, cancelCallback, options) {
    var hasCancelCallback = typeof cancelCallback === 'function';
    var isFixed = cancelCallback === true || hasCancelCallback;
    var errorCallback = null;
    var params = [title, message, isFixed];

    if (isIos()) {
      options = options && typeof options === 'object' ? options : {};
      errorCallback = typeof options.errorCallback === 'function' ? options.errorCallback : null;
      params = params.concat([
        optionOrDefault(options, 'overlayOpacity', 0.35),
        optionOrDefault(options, 'textColorRed', 1),
        optionOrDefault(options, 'textColorGreen', 1),
        optionOrDefault(options, 'textColorBlue', 1),
        optionOrDefault(options, 'fontSize', 16),
        hasCancelCallback
      ]);
    }

    exec(hasCancelCallback ? cancelCallback : null, errorCallback, 'SpinnerDialog', 'show', params);
  },

  hide: function (wpStatusbar, success, fail) {
    exec(success, fail, 'SpinnerDialog', 'hide', [wpStatusbar]);
  }
};
