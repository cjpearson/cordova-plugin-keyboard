var wd = require("wd");

require('colors');

var chai = require("chai"),
    chaiAsPromised = require("chai-as-promised");

chai.use(chaiAsPromised);

var should = chai.should();
chaiAsPromised.transferPromiseness = wd.transferPromiseness;

exports.should = should;