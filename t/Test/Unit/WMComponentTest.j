@import <OJUnit/OJTestCase.j>
@import <WM/Classes.j>
@import "../../Application.j"
@import "../../Component/WMTest/Home.j"

var application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation WMComponentTest : OJTestCase

- (void) testInstantiation {
    var component = [WMTestHome new];
    [self assertNotNull:component message:"instantiated ok"];
}

- (void) testBasicRendering {
    var component = [WMTestHome new];
    var o = [component render];
    [self assertTrue:(o && o.match(/Jabberwock/)) message:"Rendered directly"];
}

- (void) testFancyRendering {
    var component = [WMTestHome new];
    var response = [component response];
    [component appendToResponse:response inContext:nil];
    [self assertTrue:[response content].match(/Jabberwock/) message:"Rendered via response"];
}

- (void) testDirectAccess {
    var component = [WMTestHome new];
    [component setAllowsDirectAccess:true];
    var o = [component render];
    [self assertTrue:o.match(/Zabzib/) message:"Direct access of properties working"];
}

@end
