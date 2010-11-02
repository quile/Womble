@import <OJUnit/OJTestCase.j>
@import <WM/WMRequest.j>

// just use this to mock the env.
var MOCK = require("jack/mock");
var REQUEST = require("jack/request");

@implementation WMRequestTest : OJTestCase
{
}

- (void) testCreate {
    var env = MOCK.MockRequest.envFor("GET", "/fee/fi/fo/fum");
    [self assert:env['PATH_INFO'] equals:"/fee/fi/fo/fum"];

    var req = new REQUEST.Request(env);
    [self assert:req.pathInfo() equals:"/fee/fi/fo/fum"];
    [self assert:req.requestMethod() equals:"GET"];

    // should be ok
    var wmreq = [[WMRequest alloc] initWithJackRequest:req];
    [self assert:[wmreq uri] equals:"/fee/fi/fo/fum" message:"uri is cool"];
    [self assert:[wmreq queryString] equals:"" message:"no query string"];

    var wmreq = [[WMRequest alloc] initWithEnv:env];
    [self assert:[wmreq uri] equals:"/fee/fi/fo/fum" message:"uri is cool"];
    [self assert:[wmreq queryString] equals:"" message:"no query string"];
}

- (void) testCreateWithQueryString {
    var env = MOCK.MockRequest.envFor("GET", "/fee/fi/fo/fum?favouriteColour=Blue%20No%20Red&airspeedVelocityOfUnladenSwallow=Unknown");
    [self assert:env['PATH_INFO'] equals:"/fee/fi/fo/fum"];

    var wmreq = [[WMRequest alloc] initWithEnv:env];
    [self assert:[wmreq uri] equals:"/fee/fi/fo/fum" message:"url is still ok"];
    [self assert:[wmreq formValueForKey:"favouriteColour"] equals:"Blue No Red" message:"qd value is ok"];
    [self assert:[wmreq formValueForKey:"airspeedVelocityOfUnladenSwallow"] equals:"Unknown" message:"2nd qd value is ok"];
}

- (void) testCreateWithQueryStringWithRepeatedKey {
    var env = MOCK.MockRequest.envFor("GET", "/foo?favouriteColour=Blue&favouriteColour=Red");
    var wmreq = [[WMRequest alloc] initWithEnv:env];
    [self assert:[wmreq uri] equals:"/foo"];
    [self assert:[wmreq formValueForKey:"favouriteColour"] equals:["Blue", "Red"]];
}

@end
