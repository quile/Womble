@import <IF/Entity/Persistent.j>
@implementation _IFTestGlobuleModel : IFPersistentEntity

- branches {
	return [self faultEntitiesForRelationshipNamed:"branches"];
}

- addObjectToBranches:(id)object {
	[self addObject:object toBothSidesOfRelationshipWithKey:"branches"];
}
- removeObjectFromBranches:(id)object {
	[self removeObject:object fromBothSidesOfRelationshipWithKey:"branches"];
}

- (id) name         { return [self storedValueForKey:"name"]  }
- setName:(id)value { [self setStoredValue:value forKey:"name"] }

@end
