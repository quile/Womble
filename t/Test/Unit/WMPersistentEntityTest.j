@import <WM/Entity/WMPersistentEntity.j>
@import "../../DBTestCase.j"
@import "../../Application.j"
@import "../../Entity/Ground.j"

application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation WMPersistentEntityTest : DBTestCase

- (void) testCreation {
   var d = [WMDictionary newFromObject:{ "colour": "chartreuse", }];
   var e = [WMTestGround newFromDictionary:d];
   [self assert:[e storedValueForKey:"colour"] equals:"chartreuse"];
}

@end
