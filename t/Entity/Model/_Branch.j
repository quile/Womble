@import <WM/Entity/Persistent.j>

@implementation _WMTestBranchModel : WMPersistentEntity
{
}

// These relationship methods are automatically generated:

- trunk { return [self faultEntityForRelationshipNamed:"trunk"] }
- setTrunk:(id)object {
	if (object) {
	    [self addObject:object toBothSidesOfRelationshipWithKey:"trunk"];
	} else {
	    [self setValue:nil ofToOneRelationshipNamed:"trunk"];
	}
}

- globules { return [self faultEntitiesForRelationshipNamed:"globules"] }
- addObjectToGlobules:(id)object {
	[self addObject:object toBothSidesOfRelationshipWithKey:"globules"];
}
- removeObjectFromGlobules:(id)object {
	[self removeObject:object fromBothSidesOfRelationshipWithKey:"globules"];
}

- (id) trunkId    { return [self storedValueForKey:"trunkId"]  }
- setTrunkId:(id)value { [self setStoredValue:value forKey:"trunkId"] }
- (id) length    { return [self storedValueForKey:"length"]  }
- setLength:(id)value { [self setStoredValue:value forKey:"length"] }
- (id) zabId    { return [self storedValueForKey:"zabId"]  }
- setZabId:(id)value { [self setStoredValue:value forKey:"zabId"] }
- (id) leafCount    { return [self storedValueForKey:"leafCount"]  }
- setLeafCount:(id)value { [self setStoredValue:value forKey:"leafCount"] }
- (id) zabType    { return [self storedValueForKey:"zabType"]  }
- setZabType:(id)value { [self setStoredValue:value forKey:"zabType"] }

@end
