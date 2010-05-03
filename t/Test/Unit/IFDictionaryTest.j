@import <OJUnit/OJTestCase.j>
@import <IF/Dictionary.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPKeyValueCoding.j>

@implementation IFDictionaryTest : OJTestCase
{
}

- (void) testArrayFromObject {
    var o = new Object();
    o.foo = "bar";
    o.baz = "bum";
    var a = [IFDictionary dictionaryFromObject:o];
    [self assert:[[a allKeys] count] equals:2 message:"New dictionary has correct count"];
    [self assert:[a objectForKey:"foo"] equals:"bar" message:"key/value pair seems ok"];
}

@end
