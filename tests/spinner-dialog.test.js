'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const root = path.resolve(__dirname, '..');
const javascriptSource = fs.readFileSync(path.join(root, 'www', 'SpinnerDialog.js'), 'utf8');

function loadPlugin(platformId, userAgent) {
  const calls = [];
  const sandbox = {
    cordova: { platformId },
    navigator: { userAgent: userAgent || '' },
    module: { exports: {} },
    exports: {},
    require: function (id) {
      assert.equal(id, 'cordova/exec');
      return function () {
        calls.push(Array.from(arguments));
      };
    }
  };

  vm.runInNewContext(javascriptSource, sandbox, { filename: 'SpinnerDialog.js' });
  return { api: sandbox.module.exports, calls };
}

test('iOS show keeps the public argument order and supplies defaults', function () {
  const loaded = loadPlugin('ios');
  loaded.api.show('Title', 'Message', false);

  assert.equal(loaded.calls.length, 1);
  assert.equal(loaded.calls[0][2], 'SpinnerDialog');
  assert.equal(loaded.calls[0][3], 'show');
  assert.deepEqual(Array.from(loaded.calls[0][4]), [
    'Title', 'Message', false, 0.35, 1, 1, 1, 16, false
  ]);
});

test('iOS accepts zero opacity and color component values', function () {
  const loaded = loadPlugin('ios');
  loaded.api.show(null, 'Transparent overlay', true, {
    overlayOpacity: 0,
    textColorRed: 0,
    textColorGreen: 0,
    textColorBlue: 0,
    fontSize: 8
  });

  assert.deepEqual(Array.from(loaded.calls[0][4]), [
    null, 'Transparent overlay', true, 0, 0, 0, 0, 8, false
  ]);
});

test('function callback retains legacy fixed behavior and is registered once', function () {
  const loaded = loadPlugin('ios');
  const cancel = function () {};
  const error = function () {};
  loaded.api.show(null, 'Fixed', cancel, { errorCallback: error });

  assert.equal(loaded.calls[0][0], cancel);
  assert.equal(loaded.calls[0][1], error);
  assert.equal(loaded.calls[0][4][2], true);
  assert.equal(loaded.calls[0][4][8], true);
});

test('Android arguments and callbacks remain unchanged by iOS options', function () {
  const loaded = loadPlugin('android');
  const cancel = function () {};
  loaded.api.show('Title', 'Message', cancel, { overlayOpacity: 0.9 });

  assert.equal(loaded.calls[0][0], cancel);
  assert.equal(loaded.calls[0][1], null);
  assert.deepEqual(Array.from(loaded.calls[0][4]), ['Title', 'Message', true]);
});

test('hide preserves its legacy signature', function () {
  const loaded = loadPlugin('ios');
  const success = function () {};
  const failure = function () {};
  loaded.api.hide(true, success, failure);

  assert.equal(loaded.calls[0][0], success);
  assert.equal(loaded.calls[0][1], failure);
  assert.equal(loaded.calls[0][3], 'hide');
  assert.deepEqual(Array.from(loaded.calls[0][4]), [true]);
});

