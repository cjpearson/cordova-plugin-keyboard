"use strict";

require("./helpers/setup");

var CONTEXT_NATIVE_APP = 'NATIVE_APP';

var wd = require("wd"),
    serverConfigs = require('./helpers/appium-servers'),
    path = require('path');

describe("Keyboard Tests", function () {
    this.timeout(300000);

    var driver;
    var allPassed = true,
        username = process.env.PRIVATE_USERNAME,
        password = process.env.PRIVATE_PASSWORD,
        platform = process.env.PLATFORM || 'ios',
        iOSDeviceUDID = process.env.IOS_UDID;

    function setupWithAppiumServer(serverConfig) {
        return wd.promiseChainRemote(serverConfig);
    }

    function setupLogging(driver) {
        require("./helpers/logging").configure(driver);
    }

    function addCapabilitiesAndInit(capabilities, driver) {
        var desired = Object.assign({}, capabilities[platform]);
        desired.app = require("./helpers/apps")[platform + 'Sim'];

        if (platform === 'ios' && iOSDeviceUDID) {
            desired.app = require("./helpers/apps")[platform + 'Device'];
            desired.udid = iOSDeviceUDID;
        }

        // if (platform === 'android') {
        //   desired.appPackage = process.env.APP_PACKAGE;
        //   desired.appActivity = process.env.APP_ACTIVITY;
        // }

        // if (process.env.SAUCE) {
        //   desired.name = platform + ' - Can login';
        //   desired.tags = ['sample'];
        // }
        return driver.init(desired);
    }

    function switchToUIWebViewContext(driver) {
        // instead of default NATIVE_APP context
        return driver.contexts().then(function (contexts) {
            var webViewContext = contexts.filter(function (context) {
                return context.indexOf('WEBVIEW') !== -1;
            })[0];
            console.log('webViewContext', webViewContext);
            return driver.context(webViewContext);
        });
    }

    before(function () {
        var serverConfig = process.env.SAUCE ? serverConfigs.sauce : serverConfigs.local;
        driver = setupWithAppiumServer(serverConfig);

        setupLogging(driver);

        driver = addCapabilitiesAndInit(require("./helpers/capabilities"), driver);

        return switchToUIWebViewContext(driver);
    });

    after(function () {
        return driver.quit().finally(function () {
            if (process.env.SAUCE) {
                return driver.sauceJobStatus(allPassed);
            }
        });
    });

    afterEach(function () {
        allPassed = allPassed && this.currentTest.state === 'passed';
    });

    function setShrinkView(driver, value) {
        return driver.elementByCss("#shrink-view").text().then(function(text){
            if (text.toLowerCase().indexOf((!!value).toString()) === -1) {
                return driver.elementByCss("#shrink-view").click().sleep(200);
            } else {
                return driver.sleep(0);
            }
        });
    }

    it("shrinkView=false should not shrink document ", function () {
        return driver
            .elementByCss("#height", 500)
            .text().then(function(originalText){
                var height = parseInt(originalText);

                return setShrinkView(driver, false)
                    .elementByCss("#text-field", 500)
                    .click()
                    .sleep(200)
                    .then(function(){
                        return driver.elementByCss("#height", 500).text().then(function(newText){
                            var newHeight = parseInt(newText);
                            return newHeight.should.equal(height);
                        });
            });
        });
    });

    it("shrinkView=true should shrink document ", function () {
        return driver
            .sleep(200)
            .elementByCss("#height", 500)
            .text().then(function(originalText){
                var height = parseInt(originalText);

                return setShrinkView(driver, true)
                    .elementByCss("#text-field", 500)
                    .click()
                    .sleep(200)
                    .then(function(){
                        return driver.elementByCss("#height", 500).text().then(function(newText){
                            var newHeight = parseInt(newText);
                            return (height - newHeight).should.be.above(100);
                        });
            });
        });
    });

});
