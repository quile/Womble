@import <OJUnit/OJTestCase.j>
@import <WM/Array.j>

@implementation WMArrayTest : OJTestCase
{
}

- (void) testArrayFromScalar {
    var o = "scalar";
    var a = [WMArray arrayFromObject:o];
    [self assert:[a count] equals:1 message:"New array has correct count"];
    [self assert:[a objectAtIndex:0] equals:"scalar" message:"First object is correct"];
}

- (void) testArrayFromObject {
    var o = new Object();
    o.foo = "bar";
    o.baz = "bum";
    var a = [WMArray arrayFromObject:o];
    [self assert:[a count] equals:1 message:"New array has correct count"];
    [self assert:[a objectAtIndex:0] equals:o message:"First object is correct"];
}

- (void) testIsArray {
    [self assertTrue:[WMArray isArray:[]] message:"empty squares"];
    [self assertFalse:[WMArray isArray:"quilombo!"] message:"string"];
    [self assertFalse:[WMArray isArray:""] message:"empty string"];
    [self assertTrue:[WMArray isArray:[CPArray new]] message:"Capp array"];
    [self assertTrue:[WMArray isArray:[WMArray arrayFromObject:"foo"]] message:"constructed via arrayFromObject"];
    [self assertFalse:[WMArray isArray:{}] message:"dict"];
    [self assertFalse:[WMArray isArray:{ foo:"bar" }] message:"dict with keys"];
    var foo = new Object();
    [self assertFalse:[WMArray isArray:foo] message:"js object"];
    foo.banana = "yellow";
    [self assertFalse:[WMArray isArray:foo] message:"non-empty js object"];
    foo = new Object();
    foo[0] = "mango";
    [self assertFalse:[WMArray isArray:foo] message:"object with numeric key"];
}

@end
