@import <WM/WMRequest.j>
@import <WM/WMLog.j>
@import <WM/WMArray.j>

var MOCK = require("jack/mock");

@implementation WMOfflineRequest : WMRequest
{
    id _uri;
}

+ (WMOfflineRequest) new {
    var env = MOCK.MockRequest.envFor("GET", "/");
    return [[self alloc] initWithEnv:env];
}

- (id) uri {
    return _uri || [super uri];
}

- (void) setUri:v {
    _uri = v;
}

@end
