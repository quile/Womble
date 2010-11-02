@import <OJUnit/OJTestCase.j>
@import <WM/WMDictionary.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPKeyValueCoding.j>

@implementation WMDictionaryTest : OJTestCase
{
}

- (void) testArrayFromObject {
    var o = new Object();
    o.foo = "bar";
    o.baz = "bum";
    var a = [WMDictionary dictionaryFromObject:o];
    [self assert:[[a allKeys] count] equals:2 message:"New dictionary has correct count"];
    [self assert:[a objectForKey:"foo"] equals:"bar" message:"key/value pair seems ok"];
}

@end
