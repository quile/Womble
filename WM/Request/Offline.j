@import <WM/Request.j>
@import <WM/Log.j>
@import <WM/Array.j>

var MOCK = require("jack/mock");

@implementation WMOfflineRequest : WMRequest

+ (WMOfflineRequest) new {
    var env = MOCK.MockRequest.envFor("GET", "/");
    return [[self alloc] initWithEnv:env];
}

@end
