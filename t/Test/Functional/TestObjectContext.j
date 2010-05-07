@import <IF/ObjectContext.j>
@import "Type/DataSource.j"

@implementation TestObjectContext : IFDataSourceTest

- (void) setUp {
    [super setUp];
    [oc init];
}

/*
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
*/

- (void) testGetChangedObjects {
    [IFLog setLogMask:0xffff];
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
    [oc saveChanges];
    [IFLog setLogMask:0x0000];

    [self assert:[[oc changedEntities] count] equals:0 message:"oc has no changed objects"];
    [self assert:[[oc addedEntities] count] equals:0 message:"oc has no added entities"];
    [self assert:[[oc trackedEntities] count] equals:3 message:"oc has three tracked entities"];
}


@end
