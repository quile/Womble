@import <WM/Entity/Persistent.j>
@implementation _WMTestRootModel : WMPersistentEntity

- ground {
	return [self faultEntityForRelationshipNamed:"ground"];

}

- setGround:(id)object {
	if (object) {
	    [self addObject:object toBothSidesOfRelationshipWithKey:"ground"];
	} else {
	    [self setValue:value ofToOneRelationshipNamed:"ground"];
	}
}

- trunk {
	return [self faultEntityForRelationshipNamed:"trunk"];
}

- setTrunk:(id)object {
	if (object) {
	    [self addObject:object toBothSidesOfRelationshipWithKey:"trunk"];
	} else {
	    [self setValue:nil ofToOneRelationshipNamed:"trunk"];
	}
}

- (id) groundId         { return [self storedValueForKey:"groundId"]  }
- setGroundId:(id)value { [self setStoredValue:value forKey:"groundId"] }
- (id) title         { return [self storedValueForKey:"title"]  }
- setTitle:(id)value { [self setStoredValue:value forKey:"title"] }

@end
