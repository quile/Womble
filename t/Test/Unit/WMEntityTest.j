@import <OJUnit/OJTestCase.j>
@import <WM/WMEntity.j>

@implementation FooEntity : WMEntity
{
    id banana @accessors;
    id mango @accessors;
}

- foo {
    return "bar!";
}
@end


@implementation WMEntityTest : OJTestCase

- (void) testCreate {
    var e = [FooEntity new];
    [self assertNotNull:e message:"created empty entity"];
    [e setBanana:"zap!"];
    [self assert:[e banana] equals:"zap!" message:"entity property set correctly"];

    var d = { "banana":"yellow", "mango":"orange" };
    var f = [FooEntity newFromDictionary:d];
    [self assert:[f banana] equals:"yellow" message:"banana initialised"];
    [self assert:[f mango] equals:"orange" message:"orange initialised"];
}

@end
