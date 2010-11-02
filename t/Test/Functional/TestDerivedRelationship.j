@import <OJUnit/OJTestCase.j>
@import <WM/WMApplication.j>
@import "Type/DataSource.j"

var application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation TestDerivedRelationship : WMDataSourceTest

// Test relationship traversal and derived relationships

// Test: the new code that handles derived data sources; basically
// at allows any FetchSpecification (almost) to be used as a relationship
// in another query

- (void) testBasic {
    var elastic = [WMTestElastic new];

    // grab a branch
    var trunk = [[oc allEntities:"WMTestTrunk"] objectAtIndex:0]
    [self assertNotNull:trunk message:"Grabbed a trunk"];

    [elastic setSourceId:[trunk id]];
    [elastic setSourceType:"WMTestTrunk"];
    [elastic setPling:"Bloop!"];
    [elastic save];

    // This finds branches
    var dq = [WMKeyValueQualifier key:"length > %@", 4];
    var dfs = [WMFetchSpecification new:"WMTestBranch" :dq];

    [self assert:[oc countOfEntitiesMatchingFetchSpecification:dfs] equals:1 message:"Found one entity with basic fs"];

    // This finds Elastics
    var dq2 = [WMAndQualifier and:[
        [WMKeyValueQualifier key:"sourceId = %@", [trunk id]],
        [WMKeyValueQualifier key:"sourceType = %@", "WMTestTrunk"]
        ]];
    var dfs2 = [WMFetchSpecification new:"WMTestElastic" :dq2];

    [self assert:[oc countOfEntitiesMatchingFetchSpecification:dfs2] equals:1 message:"Found one entity with basic fs"];

    // dfs finds branches with length > 4, so let's use that as a derived data source

    var fs = [WMFetchSpecification new:"WMTestTrunk" :nil];

    // Commented out because having more than one derived data source for now
    // doesn't work; it gets the bind values in the wrong order;
    // TODO : fix this limitation!

    // $fs->addDerivedDataSourceWithNameAndQualifier($dfs, "LongBranches",
    //                               WM::Qualifier->key("LongBranches.trunkId = id"));

    [fs addDerivedDataSource:dfs2 withName:"BendyElastics" andQualifier:
            [WMAndQualifier and:[
                [WMKeyValueQualifier key:"BendyElastics.sourceId = id"],
                [WMKeyValueQualifier key:"BendyElastics.sourceType = 'WMTestTrunk'"],
                ]]];
    var r = [oc entitiesMatchingFetchSpecification:fs];
    [self assert:[r count] equals:1 message:"Found one trunk"];

    // add a qualifier across the derived relationship:
    [fs setQualifier:[WMKeyValueQualifier key:"BendyElastics.pling = 'Bloop!'"]];
    var r = [oc entitiesMatchingFetchSpecification:fs];
    [self assert:[r count] equals:1 message:"Found one trunk when qualifying across derived relationship"];

    // change the qualifier not to match
    [fs setQualifier:[WMKeyValueQualifier key:"BendyElastics.pling = 'Fang!'"]];
    var r = [oc entitiesMatchingFetchSpecification:fs];
    [self assert:[r count] equals:0 message:"Found no trunks when qualifying across derived relationship with non-matching qual"];

    [elastic _deleteSelf];
}

1;
