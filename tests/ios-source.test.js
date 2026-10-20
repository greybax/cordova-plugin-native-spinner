'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '..');
const iosSource = fs.readFileSync(path.join(root, 'src', 'ios', 'CDVSpinnerDialog.m'), 'utf8');
const packageJson = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const pluginXml = fs.readFileSync(path.join(root, 'plugin.xml'), 'utf8');

test('iOS implementation avoids process-global window and orientation APIs', function () {
  const forbidden = [
    'sharedApplication',
    'keyWindow',
    'statusBarOrientation',
    '[UIScreen mainScreen]'
  ];

  forbidden.forEach(function (token) {
    assert.equal(iosSource.includes(token), false, 'found forbidden token: ' + token);
  });
});

test('iOS implementation uses the Cordova host view and main queue', function () {
  assert.match(iosSource, /self\.viewController/);
  assert.match(iosSource, /hostView\.bounds/);
  assert.match(iosSource, /UIViewAutoresizingFlexibleWidth/);
  assert.match(iosSource, /dispatch_get_main_queue\(\)/);
});

test('iOS implementation cleans up for web view reset, disposal and scene disconnect', function () {
  assert.match(iosSource, /- \(void\)onReset/);
  assert.match(iosSource, /- \(void\)dispose/);
  assert.match(iosSource, /UISceneDidDisconnectNotification/);
  assert.match(iosSource, /removeGestureRecognizer/);
  assert.match(iosSource, /releaseActiveCallback/);
});

test('package and plugin metadata versions agree', function () {
  const match = pluginXml.match(/<plugin[\s\S]*?version="([^"]+)"/);
  assert.ok(match);
  assert.equal(match[1], packageJson.version);
  assert.equal(packageJson.version, '1.2.0');
});

