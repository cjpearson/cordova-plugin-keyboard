/*global Windows, WinJS, cordova, module, require*/

var inputPane = Windows.UI.ViewManagement.InputPane.getForCurrentView();
var keyboardScrollDisabled = false;
var isVisible = false;

inputPane.addEventListener('hiding', function () {
    cordova.fireWindowEvent('keyboardWillHide');
    cordova.fireWindowEvent('keyboardHeightWillChange', { keyboardHeight: 0 });
    isVisible = false;
    cordova.fireWindowEvent('keyboardDidHide');
});

inputPane.addEventListener('showing', function (e) {
    cordova.fireWindowEvent('keyboardWillShow');
    if (keyboardScrollDisabled) {
        // this disables automatic scrolling of view contents to show focused control
        e.ensuredFocusedElementInView = true;
    }
    cordova.fireWindowEvent('keyboardHeightWillChange', { keyboardHeight: e.occludedRect.height });
    isVisible = true;
    cordova.fireWindowEvent('keyboardDidShow');
});

module.exports.disableScrollingInShrinkView  = function (disable) {
    keyboardScrollDisabled = disable;
};

module.exports.show = function () {
    if (typeof inputPane.tryShow === 'function') {
        inputPane.tryShow();
    }
};

module.exports.close = function () {
    if (typeof inputPane.tryShow === 'function') {
        inputPane.tryHide();
    }
};

module.exports.shrinkView = function () {
    //DO NOTHING
};

module.exports.hideFormAccessoryBar = function () {
    //DO NOTHING
};

require("cordova/exec/proxy").add("Keyboard", module.exports);
