@import <OJUnit/OJTestCase.j>
@import <WM/Template.j>

// Normally this comes from the application config
// but 
var TEMPLATE_ROOT = "t/templates";

@implementation WMTemplateTest : OJTestCase

- (void) testInitialise {
    var tt = [WMTemplate newWithName:"t1.html"
                            andPaths:[TEMPLATE_ROOT + "/Foo/en", TEMPLATE_ROOT + "/Bar/en"]
                         shouldCache:false];
    [self assertNotNull:tt message:"Loaded t1.html"];
    [self assert:[tt contentElementCount] equals:1 message:"One element in template"];
    [self assert:[tt language] equals:"en" message:"Language is correct"];
    [self assertTrue:([tt content][0].match("Foo")) message:"Template came from right place"];
    [self assertFalse:[WMTemplate hasCachedTemplateForPath:[tt fullPath]] message:"Not cached"];

    tt = [WMTemplate newWithName:"t1.html"
                            andPaths:[TEMPLATE_ROOT + "/Bar/en", TEMPLATE_ROOT + "/Foo/en"]
                         shouldCache:false];
    [self assertNotNull:tt message:"Loaded t1.html"];
    [self assert:[tt contentElementCount] equals:1 message:"One element in template"];
    [self assert:[tt language] equals:"en" message:"Language is correct"];
    [self assertTrue:([tt content][0].match("Bar")) message:"Template came from right place"];
    [self assertFalse:[WMTemplate hasCachedTemplateForPath:[tt fullPath]] message:"Not cached"];
}

- (void) testCaching {
    var tt = [WMTemplate newWithName:"t1.html"
                            andPaths:[TEMPLATE_ROOT + "/Foo/en", TEMPLATE_ROOT + "/Bar/en"]
                         shouldCache:true];
    [self assertTrue:[WMTemplate hasCachedTemplateForPath:[tt fullPath]] message:"Cached"];

}

@end
