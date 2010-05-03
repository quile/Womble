@import <IF/Entity/Persistent.j>
@implementation _IFTestGroundModel : IFPersistentEntity

- roots {
	return [self faultEntitiesForRelationshipNamed:"roots"];
}

- addObjectToRoots:(id)object {
	[self addObject:object toBothSidesOfRelationshipWithKey:"roots"];
}
- removeObjectFromRoots:(id)object {
	[self removeObject:object fromBothSidesOfRelationshipWithKey:"roots"];
}

- (id) colour    { return [self storedValueForKey:"colour"] }
- setColour:(id)value { [self setStoredValue:value forKey:"colour"] }

@end
