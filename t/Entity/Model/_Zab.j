@import <IF/Entity/Persistent.j>
@implementation _IFTestZabModel : IFPersistentEntity

- (id) title         { return [self storedValueForKey:"title"] }
- setTitle:(id)value { [IFLog debug:"title value is " + value];
                       [self setStoredValue:value forKey:"title"] }

@end
