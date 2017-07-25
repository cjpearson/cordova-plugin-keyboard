/*jslint node: true */

'use strict';

if (process.env.DEV) {
    exports.iosSim = "test/platforms/ios/build/emulator/KeyboardTests.app";
    exports.iosDevice = "test/platforms/ios/build/device/KeyboardTests.app";
} else {
    //exports.iosWebviewApp = "http://appium.github.io/appium/assets/WebViewApp7.1.app.zip";
    //exports.androidApiDemos = "http://appium.github.io/appium/assets/ApiDemos-debug.apk";
    //exports.selendroidTestApp = "http://appium.github.io/appium/assets/selendroid-test-app-0.10.0.apk";
}
