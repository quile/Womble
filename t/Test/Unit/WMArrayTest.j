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

@end
