@import <WM/WMObjectContext.j>
@import <WM/WMQuery.j>
@import "Type/DataSource.j"

var UTIL = require("util");

@implementation TestObjectContext : WMDataSourceTest

- (void) setUp {
    [super setUp];
    [oc init];
}

- (void) testTrackNewObject {
    var e = [WMTestGlobule new];
    [self assertFalse:[e isTrackedByObjectContext] message:"New object is not being tracked"];
    [self assertFalse:[oc entityIsTracked:e] message:"Object context knows nothing of new object"];

    [oc trackEntity:e];
    [self assertTrue:[e isTrackedByObjectContext] message:"Object was inserted into editing context"];
    [self assertTrue:[oc entityIsTracked:e] message:"Object context knows about new object"];
}

- (void) testIgnoreObject {
    var e = [WMTestZab new];
    [self assertFalse:[e isTrackedByObjectContext] message:"New object is not being tracked"];

    [oc insertEntity:e];
    [self assertTrue:[e isTrackedByObjectContext] message:"New object is being tracked"];

    [oc forgetEntity:e];
    [self assertFalse:[e isTrackedByObjectContext] message:"New object is no longer being tracked"];
    [self assertFalse:[oc entityIsTracked:e] message:"Object context no longer knows about new object"];
}

- (void) testGetChangedObjects {
    var e = [WMTestZab newFromDictionary:{ title: "Zab 1" } ];
    var f = [WMTestZab newFromDictionary:{ title: "Zab 2" } ];
    var g = [WMTestZab newFromDictionary:{ title: "Zab 3" } ];
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
    [WMLog debug:[oc addedEntities]];
    [oc saveChanges];

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
    var e = [WMTestBranch newFromDictionary:{ leafCount:10, length:16 }];
    var f = [WMTestBranch newFromDictionary:{ leafCount:12, length:8 }];
    var g = [WMTestBranch newFromDictionary:{ leafCount:14, length:6 }];
    var h = [WMTestBranch newFromDictionary:{ leafCount:16, length:4 }];

    [self assert:[[oc trackedEntities] count] equals:0 message:"no tracked entities yet"];
    [oc trackEntities:[e, f, g]];
    [self assert:[[oc trackedEntities] count] equals:3 message:"three tracked entities now"];
    [self assert:[[oc addedEntities] count] equals:3 message:"three added entities now"];

    var t = [WMTestTrunk newFromDictionary:{ thickness: 3 }];
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
    var re = [oc entity:"WMTestBranch" withPrimaryKey:[e id]];
    [self assertTrue:(re === e) message:"object fetched with pk should return unique instance"];

    var re2 = [oc entity:"WMTestBranch" withPrimaryKey:[e id]];
    [self assertTrue:(re2 === re) message:"fetched again, same again"];

    var brs = [t branches];
    [self assertTrue:[brs containsObject:e] message:"e is in branches"];
    [self assertTrue:[brs containsObject:f] message:"f is in branches"];
    [self assertTrue:[brs containsObject:g] message:"g is in branches"];
    [self assertTrue:[brs containsObject:h] message:"h is in branches"];

    // make sure something fetched via a query is uniqued too
    var newb = [[[WMQuery new:"WMTestBranch"] filter:"leafCount = %@", 12] first];
    [self assertTrue:(newb === f) message:"Fetched result is matched with in-memory result"];

    // what about traversing across a relationship?
    var newt = [[[[WMQuery new:"WMTestTrunk"] filter:"branches.leafCount = %@", 10] prefetch:"branches"] first];
    [self assertTrue:(newt === t) message:"Fetched result is matched with in-memory result"];
    [self assert:[[newt _cachedEntitiesForRelationshipNamed:"branches"] count] equals:4 message:"Four branches attached to in-memory"];
    [self assert:[[newt branches] count] equals:4 message:"Four branches when fetched via <branches> method"];
}

- (void) testFaultingAndUniquing {
    var e = [WMTestBranch newFromDictionary:{ leafCount:10, length:16 }];
    var f = [WMTestBranch newFromDictionary:{ leafCount:12, length:8 }];
    var g = [WMTestBranch newFromDictionary:{ leafCount:14, length:6 }];

    var t = [WMTestTrunk newFromDictionary:{ thickness: 3 }];
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

    var rt = [oc entity:"WMTestTrunk" withPrimaryKey:[t id]];
    //[self assert:[[rt branches] count] equals:1 message:"Refetched trunk has 1"];

    // add another
    [rt addObjectToBranches:f];

    // calling branches here should fault in from the DB
    [self assert:[[rt _cachedEntitiesForRelationshipNamed:"branches"] count] equals:1 message:"One cached entity"];
    [self assert:[[rt branches] count] equals:2 message:"Now two"];
    [self assert:[[rt _cachedEntitiesForRelationshipNamed:"branches"] count] equals:2 message:"Two cached entities"];
}

- (void) testTraversedRelationshipsBeforeCommit {
    var branch = [WMTestBranch newFromDictionary:{ leafCount: 33, length: 12 }];
    var trunk = [WMTestTrunk newFromDictionary:{ thickness: 20 }];
    var root = [WMTestRoot newFromDictionary:{ title:"Big Tree!"}];

    [oc trackEntity:root];
    [root setTrunk:trunk];
    [trunk addObjectToBranches:branch];

    [self assertNotNull:[root trunk] message:"in-memory connection made"];
    [self assert:[[trunk branches] count] equals:1];
    [self assert:[[oc addedEntities] count] equals:3 message:"oc has correct number of added entities"];
    [self assert:[[[root trunk] branches] count] equals:1 message:"traversal gives correct results"];
}

- (void) testTraversedRelationshipsAfterCommit {
    var branch = [WMTestBranch newFromDictionary:{ leafCount: 33, length: 12 }];
    var trunk = [WMTestTrunk newFromDictionary:{ thickness: 888 }];
    var root = [WMTestRoot newFromDictionary:{ title:"Big Tree!"}];

    [oc trackEntity:root];
    [root setTrunk:trunk];
    [trunk addObjectToBranches:branch];
    [oc saveChanges];
    [oc clearTrackedEntities];

    branch = nil;
    trunk = nil;
    root = nil;
    // TODO: ensure garbage is collected here?

    var rr = [oc entity:"WMTestRoot" matchingQualifier:[WMKeyValueQualifier key:"title = %@", "Big Tree!"]];
    [self assertNotNull:rr message:"Refetch root"];
    var rt = [oc entity:"WMTestTrunk" matchingQualifier:[WMKeyValueQualifier key:"thickness = %@", 888]];
    [self assertNotNull:rt message:"Refetch trunk"];
    var br = [oc entity:"WMTestBranch" matchingQualifier:[WMKeyValueQualifier key:"leafCount = %@", 33]];
    [self assertNotNull:br message:"Refetch branch"];

    [self assertTrue:([rr trunk] === rt) message:"related trunk is same as refetched"];
    [self assertTrue:([[rt branches] objectAtIndex:0] === br) message:"related branch is same as refetched"];
}

- (void) testChangedObjects {
    // first flush the OC
    [oc clearTrackedEntities];
    [self assert:[[oc trackedEntities] count] equals:0 message:"OC has been flushed"];

    [self assertTrue:[oc trackingIsEnabled] message:"Tracking is enabled"];


    // fetch any branch object
    var branch = [[WMQuery new:"WMTestBranch"] first];
    [self assertNotNull:branch message:"fetched a branch from the DB"];
    [self assert:[[oc trackedEntities] count] equals:1 message:"OC is tracking one entity"];

    // flush the OC
    [oc clearTrackedEntities];
    [self assert:[[oc trackedEntities] count] equals:0 message:"OC has been flushed"];
    [self assertFalse:[branch isTrackedByObjectContext] message:"branch is no longer being tracked"];
}

@end
