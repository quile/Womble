@import <OJUnit/OJTestCase.j>
@import <WM/Component.j>
@import <WM/Response.j>
@import <WM/Template.j>
@import "../../Component/WMTest/Home.j"

@implementation WMComponentTest : OJTestCase

- (void) testInstantiation {
    var component = [WMTestHome new];
    [self assertNotNull:component message:"instantiated ok"];

    var o = [component render];
    [self assertTrue:(o && o.match(/Jabberwock/)) message:"Rendered directly"];

    var response = [component response];
    [component appendToResponse:response inContext:nil];

    [self assertTrue:[response content].match(/Jabberwock/) message:"Rendered via response"];
}

@end