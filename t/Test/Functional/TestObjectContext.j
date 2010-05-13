@import <IF/ObjectContext.j>
@import <IF/Query.j>
@import "Type/DataSource.j"

var UTIL = require("util");

@implementation TestObjectContext : IFDataSourceTest

- (void) setUp {
    [super setUp];
    [oc init];
}

- (void) testTrackNewObject {
    var e = [IFTestGlobule new];
    [self assertFalse:[e isTrackedByObjectContext] message:"New object is not being tracked"];
    [self assertFalse:[oc entityIsTracked:e] message:"Object context knows nothing of new object"];

    [oc trackEntity:e];
    [self assertTrue:[e isTrackedByObjectContext] message:"Object was inserted into editing context"];
    [self assertTrue:[oc entityIsTracked:e] message:"Object context knows about new object"];
}

- (void) testIgnoreObject {
    var e = [IFTestZab new];
    [self assertFalse:[e isTrackedByObjectContext] message:"New object is not being tracked"];

    [oc insertEntity:e];
    [self assertTrue:[e isTrackedByObjectContext] message:"New object is being tracked"];

    [oc forgetEntity:e];
    [self assertFalse:[e isTrackedByObjectContext] message:"New object is no longer being tracked"];
    [self assertFalse:[oc entityIsTracked:e] message:"Object context no longer knows about new object"];
}

- (void) testGetChangedObjects {
    var e = [IFTestZab newFromDictionary:{ title: "Zab 1" } ];
    var f = [IFTestZab newFromDictionary:{ title: "Zab 2" } ];
    var g = [IFTestZab newFromDictionary:{ title: "Zab 3" } ];
    [self assert:[e title] equals:"Zab 1" message:"Set title correctly"];

    [self assertFalse:[e isTrackedByObjectContext]];
    [self assertFalse:[f isTrackedByObjectContext]];
    [self assertFalse:[g isTrackedByObjectContext]];

    [oc insertEntity:e];
    [oc insertEntity:f];
    [oc insertEntity:g];
    [self assertTrue:[e isTrackedByObjectContext]];
    [self assertTrue:[f isTrackedByObjectContext]];
    [self assertTrue:[g isTrackedByObjectContext]];

    [self assert:[[oc changedEntities] count] equals:0 message:"oc has no changed objects"];
    [self assert:[[oc addedEntities] count] equals:3 message:"oc has three added entities"];
    [self assert:[[oc trackedEntities] count] equals:3 message:"oc has three tracked entities"];

    // This should commit the new objects
    [IFLog setLogMask:0xffff];
    [IFLog debug:[oc addedEntities]];
    [oc saveChanges];
    [IFLog setLogMask:0x0000];

    [self assert:[[oc changedEntities] count] equals:0 message:"oc has no changed objects"];
    [self assert:[[oc addedEntities] count] equals:0 message:"oc has no added entities"];
    [self assert:[[oc trackedEntities] count] equals:3 message:"oc has three tracked entities"];

    [f setTitle:"Zab 2a"];
    [self assert:[[oc changedEntities] count] equals:1 message:"oc has one changed entity"];
    [self assert:[[oc changedEntities] objectAtIndex:0] equals:f message:"... and it's f"];
    [oc saveChanges];
    [self assert:[[oc changedEntities] count] equals:0 message:"flushed oc has no changed entity"];
}

- (void) testUniquing {
    var e = [IFTestBranch newFromDictionary:{ leafCount:10, length:16 }];
    var f = [IFTestBranch newFromDictionary:{ leafCount:12, length:8 }];
    var g = [IFTestBranch newFromDictionary:{ leafCount:14, length:6 }];
    var h = [IFTestBranch newFromDictionary:{ leafCount:16, length:4 }];

    [self assert:[[oc trackedEntities] count] equals:0 message:"no tracked entities yet"];
    [oc trackEntities:[e, f, g]];
    [self assert:[[oc trackedEntities] count] equals:3 message:"three tracked entities now"];
    [self assert:[[oc addedEntities] count] equals:3 message:"three added entities now"];

    var t = [IFTestTrunk newFromDictionary:{ thickness: 3 }];
    [t addObjectToBranches:e];
    [t addObjectToBranches:f];
    [t addObjectToBranches:g];
    [t addObjectToBranches:h];

    [self assert:[[t relatedEntities] count] equals:4 message:"Trunk has four related entities in memory"];

    // FIXME: this shouldn't be necessary because
    // it's related to objects in the OC. 
    [oc trackEntity:t];

    [self assert:[[oc trackedEntities] count] equals:5 message:"correct # tracked entities now"];

    // this commits everyone
    [oc saveChanges];

    [self assertNotNull:[e id] message:"e has an id now"];

    // now do some basic uniquing checks
    var re = [oc entity:"IFTestBranch" withPrimaryKey:[e id]];
    [self assertTrue:(re === e) message:"object fetched with pk should return unique instance"];

    var re2 = [oc entity:"IFTestBranch" withPrimaryKey:[e id]];
    [self assertTrue:(re2 === re) message:"fetched again, same again"];

    var brs = [t branches];
    [self assertTrue:[brs containsObject:e] message:"e is in branches"];
    [self assertTrue:[brs containsObject:f] message:"f is in branches"];
    [self assertTrue:[brs containsObject:g] message:"g is in branches"];
    [self assertTrue:[brs containsObject:h] message:"h is in branches"];

    // make sure something fetched via a query is uniqued too
    var newb = [[[IFQuery new:"IFTestBranch"] filter:"leafCount = %@", 12] first];
    [self assertTrue:(newb === f) message:"Fetched result is matched with in-memory result"];

    // what about traversing across a relationship?
    var newt = [[[[IFQuery new:"IFTestTrunk"] filter:"branches.leafCount = %@", 10] prefetch:"branches"] first];
    [self assertTrue:(newt === t) message:"Fetched result is matched with in-memory result"];
    [self assert:[[newt _cachedEntitiesForRelationshipNamed:"branches"] count] equals:4 message:"Four branches attached to in-memory"];
    [self assert:[[newt branches] count] equals:4 message:"Four branches when fetched via <branches> method"];
}

- (void) testFaultingAndUniquing {
    var e = [IFTestBranch newFromDictionary:{ leafCount:10, length:16 }];
    var f = [IFTestBranch newFromDictionary:{ leafCount:12, length:8 }];
    var g = [IFTestBranch newFromDictionary:{ leafCount:14, length:6 }];

    var t = [IFTestTrunk newFromDictionary:{ thickness: 3 }];
    [t addObjectToBranches:e];
    [self assert:[[t branches] count] equals:1 message:"One branch connected"];
    [self assert:[[t _cachedEntitiesForRelationshipNamed:"branches"] count] equals:1 message:"One cached connected"];
    
    // add same one again
    [t addObjectToBranches:e];
    [self assert:[[t branches] count] equals:1 message:"One branch connected still"];
    [self assert:[[t _cachedEntitiesForRelationshipNamed:"branches"] count] equals:1 message:"One cached connected still"];

    [oc trackEntity:t];

    [oc saveChanges];
    [oc clearTrackedEntities];

    var rt = [oc entity:"IFTestTrunk" withPrimaryKey:[t id]];
    //[self assert:[[rt branches] count] equals:1 message:"Refetched trunk has 1"];

    // add another
    [rt addObjectToBranches:f];

    // calling branches here should fault in from the DB
    [self assert:[[rt _cachedEntitiesForRelationshipNamed:"branches"] count] equals:1 message:"One cached entity"];
    //[IFLog setLogMask:0xffff];
    [self assert:[[rt branches] count] equals:2 message:"Now two"];
    [self assert:[[rt _cachedEntitiesForRelationshipNamed:"branches"] count] equals:2 message:"Two cached entities"];
    //[IFLog setLogMask:0x0000];
}

@end
