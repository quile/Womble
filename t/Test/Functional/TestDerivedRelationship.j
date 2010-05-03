@import <OJUnit/OJTestCase.j>
@import <IF/Application.j>
@import "Type/DataSource.j"

var application = [IFApplication applicationInstanceWithName:"IFTest"];

@implementation TestDerivedRelationship : IFDataSourceTest

// Test relationship traversal and derived relationships

// Test: the new code that handles derived data sources; basically
// at allows any FetchSpecification (almost) to be used as a relationship
// in another query

- (void) testBasic {
    var elastic = [IFTestElastic new];
    
    // grab a branch
    var trunk = [[oc allEntities:"IFTestTrunk"] objectAtIndex:0]
    [self assertNotNull:trunk message:"Grabbed a trunk"];
    
    [elastic setSourceId:[trunk id]];
    [elastic setSourceType:"IFTestTrunk"];
    [elastic setPling:"Bloop!"];
    [elastic save];
    
    // This finds branches
    var dq = [IFKeyValueQualifier key:"length > %@", 4];
    var dfs = [IFFetchSpecification new:"IFTestBranch" :dq];

    [self assert:[oc countOfEntitiesMatchingFetchSpecification:dfs] equals:1 message:"Found one entity with basic fs"];

    // This finds Elastics
    var dq2 = [IFAndQualifier and:[
        [IFKeyValueQualifier key:"sourceId = %@", [trunk id]],
        [IFKeyValueQualifier key:"sourceType = %@", "IFTestTrunk"]
        ]];
    var dfs2 = [IFFetchSpecification new:"IFTestElastic" :dq2];

    [self assert:[oc countOfEntitiesMatchingFetchSpecification:dfs2] equals:1 message:"Found one entity with basic fs"];
    
    // dfs finds branches with length > 4, so let's use that as a derived data source

    var fs = [IFFetchSpecification new:"IFTestTrunk" :nil];

    // Commented out because having more than one derived data source for now
    // doesn't work; it gets the bind values in the wrong order;
    // TODO : fix this limitation!
    
    // $fs->addDerivedDataSourceWithNameAndQualifier($dfs, "LongBranches",
    //                               IF::Qualifier->key("LongBranches.trunkId = id"));
								
    [fs addDerivedDataSource:dfs2 withName:"BendyElastics" andQualifier:
            [IFAndQualifier and:[
                [IFKeyValueQualifier key:"BendyElastics.sourceId = id"],
                [IFKeyValueQualifier key:"BendyElastics.sourceType = 'IFTestTrunk'"],
                ]]];
    var r = [oc entitiesMatchingFetchSpecification:fs];
    [self assert:[r count] equals:1 message:"Found one trunk"];
    
    // add a qualifier across the derived relationship:
    [fs setQualifier:[IFKeyValueQualifier key:"BendyElastics.pling = 'Bloop!'"]];
    var r = [oc entitiesMatchingFetchSpecification:fs];
    [self assert:[r count] equals:1 message:"Found one trunk when qualifying across derived relationship"];
    
    // change the qualifier not to match
    [fs setQualifier:[IFKeyValueQualifier key:"BendyElastics.pling = 'Fang!'"]];
    var r = [oc entitiesMatchingFetchSpecification:fs];
    [self assert:[r count] equals:0 message:"Found no trunks when qualifying across derived relationship with non-matching qual"];

    [elastic _deleteSelf];
}

1;    
