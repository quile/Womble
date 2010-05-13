@import <WM/Entity/Persistent.j>
@implementation _WMTestTrunkModel : WMPersistentEntity

- root {
	return [self faultEntityForRelationshipNamed:"root"];
}

- setRoot:(id)object {
	if (object) {
	    [self addObject:object toBothSidesOfRelationshipWithKey:"root"];
	} else {
	    [self setValue:nil ofToOneRelationshipNamed:"root"];
	}
}

- branches {
	return [self faultEntitiesForRelationshipNamed:"branches"];
}

- addObjectToBranches:(id)object {
	[self addObject:object toBothSidesOfRelationshipWithKey:"branches"];
}
- removeObjectFromBranches:(id)object {
	[self removeObject:object fromBothSidesOfRelationshipWithKey:"branches"];
}

- (id) rootId         { return [self storedValueForKey:"rootId"]  }
- setRootId:(id)value { [self setStoredValue:value forKey:"rootId"] }
- (id) thickness         { return [self storedValueForKey:"thickness"]  }
- setThickness:(id)value { [self setStoredValue:value forKey:"thickness"] }

@end
