@import <OJUnit/OJTestCase.j>
@import <IF/Entity/UniqueIdentifier.j>

@implementation IFEntityUniqueIdentifierTest : OJTestCase

- (void) testNew {
    var uid = [IFEntityUniqueIdentifier newFromString:"FooFah,666"];
    [self assert:[uid entityName] equals:"FooFah" message:"Entity name kosher"];
    [self assert:[uid externalId] equals:"666" message:"External id kosher"];
    [self assert:[uid description] equals:"FooFah,666" message:"Description is kosher"];
}

// TODO tessssst this properly

@end
