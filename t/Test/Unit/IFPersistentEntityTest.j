@import <IF/Entity/Persistent.j>
@import "../../DBTestCase.j"
@import "../../Application.j"
@import "../../Entity/Ground.j"

application = [IFApplication applicationInstanceWithName:"IFTest"];

@implementation IFPersistentEntityTest : DBTestCase

- (void) testCreation {
   var d = [IFDictionary newFromObject:{ "colour": "chartreuse", }];
   var e = [IFTestGround newFromDictionary:d];
   [self assert:[e storedValueForKey:"colour"] equals:"chartreuse"];
}

@end
