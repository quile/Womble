@import <WM/Entity/WMPersistentEntity.j>

@implementation _WMTestZabModel : WMPersistentEntity

- (id) title         { return [self storedValueForKey:"title"] }
- setTitle:(id)value { [self setStoredValue:value forKey:"title"] }

@end
