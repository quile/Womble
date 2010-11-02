@import <WM/Entity/WMPersistentEntity.j>

@implementation _WMTestElasticModel : WMPersistentEntity

- (id) pling    { return [self storedValueForKey:"pling"] }
- setPling:(id)value { [self setStoredValue:value forKey:"pling"] }
- (id) sourceType    { return [self storedValueForKey:"sourceType"] }
- setSourceType:(id)value { [self setStoredValue:value forKey:"sourceType"] }
- (id) sourceId    { return [self storedValueForKey:"sourceId"] }
- setSourceId:(id)value { [self setStoredValue:value forKey:"sourceId"] }
- (id) targetId    { return [self storedValueForKey:"targetId"]  }
- setTargetId:(id)value { [self setStoredValue:value forKey:"targetId"] }
- (id) targetType    { return [self storedValueForKey:"targetType"]  }
- setTargetType:(id)value { [self setStoredValue:value forKey:"targetType"] }

@end
