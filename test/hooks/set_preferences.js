var fs = require('fs');
var path = require('path');

module.exports = function(context) {
    var config_template = path.join(context.opts.projectRoot, 'config_template.xml');
    var config_xml = path.join(context.opts.projectRoot, 'config.xml');
    var et = context.requireCordovaModule('elementtree');

    var data = fs.readFileSync(config_template).toString();
    var etree = et.parse(data);

    if (process.env.HideKeyboardFormAccessoryBar != null) {
        etree.getroot().append(et.Element('preference', { name: 'HideKeyboardFormAccessoryBar', value: process.env.HideKeyboardFormAccessoryBar }));
    }
    if (process.env.StatusBarOverlaysWebView != null) {
        etree.getroot().append(et.Element('preference', { name: 'StatusBarOverlaysWebView', value: process.env.StatusBarOverlaysWebView }));
    }
    if (process.env.KeyboardShrinksView != null) {
        etree.getroot().append(et.Element('preference', { name: 'KeyboardShrinksView', value: process.env.KeyboardShrinksView }));
    }

    data = etree.write({'indent': 4});
    fs.writeFileSync(config_xml, data);
}