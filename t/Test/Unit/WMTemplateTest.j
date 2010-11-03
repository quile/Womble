@import <OJUnit/OJTestCase.j>
@import <WM/WMTemplate.j>

// Normally this comes from the application config
// but
var TEMPLATE_ROOT = "t/Resources/templates";

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

    var t2 = [WMTemplate newWithName:"t1.html"
                            andPaths:[TEMPLATE_ROOT + "/Foo/en", TEMPLATE_ROOT + "/Bar/en"]
                         shouldCache:true];

    [self assertTrue:(tt === t2) message:"Same template is returned from cache"];
}

- (void) testInitWithString {
    var tt = [[WMTemplate new] initWithString:"<html><body><h1>Test</h1><p>Baz</p></body</html>" inLanguage:"en"];
    [self assert:[tt contentElementCount] equals:1 message:"One element in template"];
    [self assert:[tt language] equals:"en" message:"Language is correct"];
    [self assertTrue:([tt content][0].match("Baz")) message:"Template came from right place"];
    [self assertFalse:[WMTemplate hasCachedTemplateForPath:[tt fullPath]] message:"Not cached"];
}

- (void) testBasicContent {
    var tt = [WMTemplate new];
    [tt setContent:["<html><body><h1>", "Foo", "</h1></body></html>"]];
    [self assert:[tt contentElementCount] equals:3 message:"content has 3 elements"];
    // TODO: more
}

- (void) testIncludes {
    var tt = [WMTemplate newWithName:"IncludeTest.html"
                            andPaths:[TEMPLATE_ROOT + "/Foo/en", TEMPLATE_ROOT + "/Bar/en"]
                         shouldCache:false];

    [self assertTrue:[tt content][0].match("Bing") message:"Pulled in include"];
    [self assertTrue:[tt content][0].match("Bong") message:"Content survived include"];
    [self assertTrue:[tt content][0].match("Bang") message:"Second level include"];
}

- (void) testBindingExtraction {
    // straight binding tags
    var tt = [WMTemplate new];
    [tt setTemplateSource:"<html><body><h1>Foo!</h1><p>Bar: <binding:bar /></p></body></html>"];
    [tt extractBindingTags];
    [self assert:[tt contentElementCount] equals:3 message:"Right number of elements"];
    [self assert:[[tt content] objectAtIndex:0] equals:"<html><body><h1>Foo!</h1><p>Bar: " message:"First bit ok"];

    var be = [[tt content] objectAtIndex:1];
    [self assert:be['BINDING_NAME'] equals:"bar" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING" message:"binding type ok"];
    [self assert:be['IS_END_TAG'] equals:false message:"not an end tag"];

    [self assert:[[tt content] objectAtIndex:2] equals:"</p></body></html>" message:"Last bit ok"];
}

- (void) testConditionalExtraction {
    // if tags
    var tt = [WMTemplate new];
    [tt setTemplateSource:"<html><body><h1>Foo!</h1><p><binding_if:bar>Bar!</binding_if:bar></p></body></html>"];
    [tt extractBindingTags];
    [self assert:[tt contentElementCount] equals:5 message:"Right number of elements"];
    [self assert:[[tt content] objectAtIndex:0] equals:"<html><body><h1>Foo!</h1><p>" message:"First bit ok"];
    [self assert:[[tt content] objectAtIndex:2] equals:"Bar!" message:"Middle bit ok"];
    [self assert:[[tt content] objectAtIndex:4] equals:"</p></body></html>" message:"Last bit ok"];

    var be = [[tt content] objectAtIndex:1];
    [self assert:be['BINDING_NAME'] equals:"bar" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING_IF" message:"binding type ok"];
    [self assert:be['IS_END_TAG'] equals:false message:"not an end tag"];

    var be = [[tt content] objectAtIndex:3];
    [self assert:be['BINDING_NAME'] equals:"bar" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING_IF" message:"binding type ok"];
    [self assert:be['IS_END_TAG'] equals:true message:"is an end tag"];

    // unless
    var tt = [WMTemplate new];
    [tt setTemplateSource:"<html><body><h1>Foo!</h1><p><binding_unless:bar>Bar!</binding_unless:bar></p></body></html>"];
    [tt extractBindingTags];
    [self assert:[tt contentElementCount] equals:5 message:"Right number of elements"];
    [self assert:[[tt content] objectAtIndex:0] equals:"<html><body><h1>Foo!</h1><p>" message:"First bit ok"];
    [self assert:[[tt content] objectAtIndex:2] equals:"Bar!" message:"Middle bit ok"];
    [self assert:[[tt content] objectAtIndex:4] equals:"</p></body></html>" message:"Last bit ok"];

    var be = [[tt content] objectAtIndex:1];
    [self assert:be['BINDING_NAME'] equals:"bar" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING_UNLESS" message:"binding type ok"];
    [self assert:be['IS_END_TAG'] equals:false message:"not an end tag"];

    var be = [[tt content] objectAtIndex:3];
    [self assert:be['BINDING_NAME'] equals:"bar" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING_UNLESS" message:"binding type ok"];
    [self assert:be['IS_END_TAG'] equals:true message:"is an end tag"];
}

- (void) testConditionalBindingsWithElse {
    // else tags
    var tt = [WMTemplate new];
    [tt setTemplateSource:"<html><body><h1>Foo!</h1><p><binding_if:bar>Bar!<binding_else:bar>Baz!</binding_if:bar></p></body></html>"];
    [tt extractBindingTags];
    [tt matchStartAndEndTags];

    [self assert:[tt contentElementCount] equals:7 message:"Right number of elements"];
    [self assert:[[tt content] objectAtIndex:0] equals:"<html><body><h1>Foo!</h1><p>" message:"First bit ok"];
    [self assert:[[tt content] objectAtIndex:2] equals:"Bar!" message:"First middle bit ok"];
    [self assert:[[tt content] objectAtIndex:4] equals:"Baz!" message:"Second middle bit ok"];
    [self assert:[[tt content] objectAtIndex:6] equals:"</p></body></html>" message:"Last bit ok"];

    var be = [[tt content] objectAtIndex:1];
    [self assert:be['BINDING_NAME'] equals:"bar" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING_IF" message:"binding type ok"];
    [self assert:be['END_TAG_INDEX'] equals:5 message:"binding end index ok"];
    [self assert:be['ELSE_TAG_INDEX'] equals:3 message:"else tag is ok"];
    [self assert:be['IS_END_TAG'] equals:false message:"not an end tag"];

    be = [[tt content] objectAtIndex:3];
    [self assert:be['BINDING_NAME'] equals:"bar" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING_ELSE" message:"binding type ok"];
    [self assert:be['START_TAG_INDEX'] equals:1 message:"start tag is kosher"];
    [self assert:be['IS_END_TAG'] equals:false message:"is an end tag"];

    be = [[tt content] objectAtIndex:5];
    [self assert:be['BINDING_NAME'] equals:"bar" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING_IF" message:"binding type ok"];
    [self assert:be['START_TAG_INDEX'] equals:1 message:"start tag is ok"];
    [self assert:be['IS_END_TAG'] equals:true message:"is an end tag"];
}

- (void) testNestedConditions {
    // else tags
    var tt = [WMTemplate new];
    [tt setTemplateSource:"<html><body><h1>Foo!</h1><p><binding_if:bar>Bar!<binding_else:bar><binding_unless:gob>Gob!<binding_else:gob>Baz!</binding_unless:gob></binding_if:bar></p></body></html>"];
    [tt extractBindingTags];
    [tt matchStartAndEndTags];

    [self assert:[tt contentElementCount] equals:13 message:"Right number of elements"];
    [self assert:[[tt content] objectAtIndex:0] equals:"<html><body><h1>Foo!</h1><p>" message:"First bit ok"];
    [self assert:[[tt content] objectAtIndex:2] equals:"Bar!" message:"First middle bit ok"];
    [self assert:[[tt content] objectAtIndex:6] equals:"Gob!" message:"Second middle bit ok"];
    [self assert:[[tt content] objectAtIndex:8] equals:"Baz!" message:"Third middle bit ok"];
    [self assert:[[tt content] objectAtIndex:12] equals:"</p></body></html>" message:"Last bit ok"];

    var be = [[tt content] objectAtIndex:1];
    [self assert:be['BINDING_NAME'] equals:"bar" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING_IF" message:"binding type ok"];
    [self assert:be['END_TAG_INDEX'] equals:11 message:"binding end index ok"];
    [self assert:be['ELSE_TAG_INDEX'] equals:3 message:"else tag is ok"];
    [self assert:be['IS_END_TAG'] equals:false message:"not an end tag"];

    be = [[tt content] objectAtIndex:3];
    [self assert:be['BINDING_NAME'] equals:"bar" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING_ELSE" message:"binding type ok"];
    [self assert:be['START_TAG_INDEX'] equals:1 message:"start tag is kosher"];
    [self assert:be['END_TAG_INDEX'] equals:11 message:"end tag is kosher"];
    [self assert:be['IS_END_TAG'] equals:false message:"is an end tag"];

    be = [[tt content] objectAtIndex:5];
    [self assert:be['BINDING_NAME'] equals:"gob" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING_UNLESS" message:"binding type ok"];
    [self assert:be['ELSE_TAG_INDEX'] equals:7 message:"else tag is ok"];
    [self assert:be['END_TAG_INDEX'] equals:9 message:"end tag index is ok"];
}

- (void) testAttributeExtraction {
    var tt = [WMTemplate new];
    [tt setTemplateSource:"<html><body><h1>Foo <binding:foo name=\"ethel the aardvark\" /></h1><p>Bar: <binding:bar name=\"polly the parrot\" status=\"ex-parrot\" /></p></body></html>"];
    [tt extractBindingTags];
    [self assert:[tt contentElementCount] equals:5 message:"Right number of elements"];
    [self assert:[[tt content] objectAtIndex:0] equals:"<html><body><h1>Foo " message:"First bit ok"];

    var be = [[tt content] objectAtIndex:1];
    [self assert:be['BINDING_NAME'] equals:"foo" message:"binding name ok"];
    [self assert:be['BINDING_TYPE'] equals:"BINDING" message:"binding type ok"];
    [self assert:be['IS_END_TAG'] equals:false message:"not an end tag"];
    [self assert:be['ATTRIBUTE_HASH']['name'] equals:"ethel the aardvark" message:"first attribute extracted"];

    var be = [tt contentElementAtIndex:2];
    [self assert:be equals:"</h1><p>Bar: " message:"Last bit ok"];

    be = [tt contentElementAtIndex:3];
    [self assert:be['BINDING_TYPE'] equals:"BINDING" message:"binding type ok"];
    [self assert:be['ATTRIBUTE_HASH']['name'] equals:"polly the parrot" message:"parrot!"];
    [self assert:be['ATTRIBUTE_HASH']['status'] equals:"ex-parrot" message:"ex-parrot!"];

    [self assert:[[tt content] objectAtIndex:4] equals:"</p></body></html>" message:"Last bit ok"];
}

@end
