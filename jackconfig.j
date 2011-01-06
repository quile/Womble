// Load all your classes in your jackconfig.j file; it only gets loaded on server startup
// and its app method will be used to route requests to your Womble app

@import <WM/WMApplication.j>
@import <WM/WMLog.j>
@import <WM/WebServer/WMHandler.j>

// TODO:kd - automate the loading of app classes
// This is a pain; it'd be way better to just do
// @import "t/Classes.j"
// and have that load everything.
@import "t/Application.j";
@import "t/Component/WMTest/Form.j"
@import "t/Component/WMTest/Home.j"

[WMLog setLogMask:0xffff];

// forces the app to instantiate itself and load its config.
var _application = [WMApplication applicationInstanceWithName:"WMTest"];

// we convert the environ into a jack-specific request and then
// throw it to WM.  This is probably a bit pointless and we
// should probably generate the WM request here.
var REQUEST = require("jack/request");
var RESPONSE = require("jack/response");

exports.app = function(env) {
    // msg here
    env['womble.application.name'] = "WMTest";
    env['womble.application'] = _application;

    // TODO:kd - move the code that wraps jack requests and responses
    // into the app, and have the app return this method.
    var jrequest = new REQUEST.Request(env);
    var response = [WMWebServerHandler handler:jrequest];
    var body = [response content];
    var headers = [response headers];
    if (!headers['Content-length']) {
        headers['Content-length'] = body.length;
    }
    return new RESPONSE.Response([response status], headers, [body]);
};
