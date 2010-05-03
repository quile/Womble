@import "../../Application.j"
@import "Type/DataSource.j"
@import <IF/Log.j>
@import <IF/Model.j>
@import <IF/FetchSpecification.j>
@import <IF/Qualifier.j>
@import <IF/Array.j>
@import <IF/ObjectContext.j>
@import <IF/Helpers.js>

@implementation TestQualifier : IFDataSourceTest

- (void) testFetchById {
    var t1qualifier = [IFKeyValueQualifier key:"id = %@", [root id]];
    var t1fs = [IFFetchSpecification new:"IFTestRoot" :t1qualifier :[]];
    var t1results = [oc entitiesMatchingFetchSpecification:t1fs];
    [self assert:[t1results count] equals:1 message:"Found exactly one root by id"];

    var t1qualifier = [IFKeyValueQualifier key:"id <> %@", [root id]];
    var t1fs = [IFFetchSpecification new:"IFTestRoot" :t1qualifier :[]];
    var t1results = [oc entitiesMatchingFetchSpecification:t1fs];
    [self assert:[t1results count] equals:0 message:"Found no root by id"];
}

- (void) testMultipleQualifiers {
    var t2qualifier1 = [IFKeyValueQualifier key:"length > %@", 3];
    var t2qualifier2 = [IFKeyValueQualifier key:"leafCount < %@", 3];
    var t2qualifier3 = [IFQualifier and:[t2qualifier1, t2qualifier2]];
    var t2fs = [IFFetchSpecification new:"IFTestBranch" :t2qualifier3 :[]];
    var t2results = [oc entitiesMatchingFetchSpecification:t2fs];
    [self assertTrue:[t2results count] > 0 message:"Found branches matching qualifiers"];

    var isOk = true;
    var ren = [t2results objectEnumerator], r;
    while (r = [ren nextObject]) {
        if ([r length] > 3 && [r leafCount] < 3) { continue }
        isOk = false;
    }
    [self assertTrue:isOk message:"Matching branches have correct attributes"];

    // This will match none
    var t2qualifier1 = [IFKeyValueQualifier key:"length > %@", 50];
    var t2qualifier2 = [IFKeyValueQualifier key:"leafCount < %@", 3];
    var t2qualifier3 = [IFQualifier and:[t2qualifier1, t2qualifier2]];
    var t2fs = [IFFetchSpecification new:"IFTestBranch" :t2qualifier3];
    var t2results = [oc entitiesMatchingFetchSpecification:t2fs];
    [self assert:[t2results count] equals:0 message:"No branches found matching qualifiers"];
}

- (void) testSingleRelationshipTraversal {
    var t3qualifier = [IFKeyValueQualifier key:"branches.length = %@", 3]; 
    var t3fs = [IFFetchSpecification new:"IFTestTrunk" :t3qualifier];
    var t3results = [oc entitiesMatchingFetchSpecification:t3fs];
    [self assert:[t3results count] equals:1 message:"Exactly one trunk with a branch whose length is 3"];
}

- (void) testSingleRelationshipTraversalWithQualifiers {
    var t4qualifier1 = [IFKeyValueQualifier key:"trunk.thickness > %@", 10];
    var t4qualifier2 = [IFKeyValueQualifier key:"length > %@", 4];
    var t4qualifier3 = [IFAndQualifier and:[t4qualifier1, t4qualifier2]];
    var t4fs = [IFFetchSpecification new:"IFTestBranch" :t4qualifier3];
    var t4results = [oc entitiesMatchingFetchSpecification:t4fs];
    [self assertTrue:([t4results count] > 0) message:"Found branches with matching trunk"];
}

- (void) testMultipleRelationshipTraversal {
    var t5qualifier1 = [IFKeyValueQualifier key:"trunk.thickness > %@", 10];
    var t5qualifier2 = [IFKeyValueQualifier key:"globules.name = %@", 'Globule-1'];
    var t5qualifier3 = [IFAndQualifier and:[t5qualifier1, t5qualifier2]];
    var t5fs = [IFFetchSpecification new:"IFTestBranch" :t5qualifier3];
    var t5results = [oc entitiesMatchingFetchSpecification:t5fs];
    [self assertTrue:([t5results count] > 0) message:"Branch matching multiple different relationship traversals"];

    var t5qualifier1 = [IFKeyValueQualifier key:"trunk.thickness > %@", 10];
    var t5qualifier2 = [IFKeyValueQualifier key:"globules.name = %@", 'Foo-1'];
    var t5qualifier3 = [IFAndQualifier and:[t5qualifier1, t5qualifier2]];
    var t5fs = [IFFetchSpecification new:"IFTestBranch" :t5qualifier3];
    var t5results = [oc entitiesMatchingFetchSpecification:t5fs];
    [self assertTrue:([t5results count] == 0) message:"No branch matched"];
}

- (void) testMultipleRelationshipsWithQualifiers {
    var t6qualifier1 = [IFKeyValueQualifier key:"trunk.thickness > %@", 10];
    var t6qualifier2 = [IFKeyValueQualifier key:"globules.name = %@", 'Globule-2'];
    var t6qualifier3 = [IFKeyValueQualifier key:"leafCount = %@", 4];
    var t6qualifier4 = [IFAndQualifier and:[t6qualifier1, t6qualifier2, t6qualifier3]];
    var t6fs = [IFFetchSpecification new:"IFTestBranch" :t6qualifier4];
    var t6results = [oc entitiesMatchingFetchSpecification:t6fs];
    [self assertTrue:([t6results count] == 1) message:"Found matching branch"];
}

- (void) testPrefetchOfToOne {
    var t7qualifier1 = [IFKeyValueQualifier key:"title = %@", 'Root']; 
    var t7fs = [IFFetchSpecification new:"IFTestRoot" :t7qualifier1];
    [t7fs setPrefetchingRelationships:["trunk"]];
    var t7results = [oc entitiesMatchingFetchSpecification:t7fs];
    [self assertTrue:[t7results count] && [[[t7results objectAtIndex:0] _cachedEntitiesForRelationshipNamed:"trunk"] count] message:"Prefetching a to-one relationship"];
}

- (void) testPrefetchOfToOneWithQualifiers {
    var t8qualifier1 = [IFKeyValueQualifier key:"title = %@", 'Root'];
    var t8qualifier2 = [IFKeyValueQualifier key:"trunk.thickness > %@", 10];
    var t8qualifier3 = [IFAndQualifier and:[t8qualifier1, t8qualifier2]];
    var t8fs = [IFFetchSpecification new:"IFTestRoot" :t8qualifier3];
    [t8fs setPrefetchingRelationships:["trunk"]];
    var t8results = [oc entitiesMatchingFetchSpecification:t8fs];
    [self assertTrue:[t8results count] && [[[t8results objectAtIndex:0] _cachedEntitiesForRelationshipNamed:"trunk"] count] message:"Prefetching a to-one relationship with qualifiers"];

}

- (void) testPrefetchOfTwoToOneRelationships {
    var t9qualifier1 = [IFKeyValueQualifier key:"title = %@", 'Root'];
    var t9fs = [IFFetchSpecification new:"IFTestRoot" :t9qualifier1];
    [t9fs setPrefetchingRelationships:["ground", "trunk"]];
    var t9results = [oc entitiesMatchingFetchSpecification:t9fs];
    [self assertTrue:[t9results count]
                  && [[[t9results objectAtIndex:0] _cachedEntitiesForRelationshipNamed:"trunk"] count]
                  && [[[t9results objectAtIndex:0] _cachedEntitiesForRelationshipNamed:"ground"] count]
            message:"Prefetching two to-one relationships in one fetch"];
}

- (void) testPrefetchOfToOneWithNoQualifiers {
    var t7fs = [IFFetchSpecification new:"IFTestRoot" :nil];
    [t7fs setPrefetchingRelationships:["trunk"]];
    var t7results = [oc entitiesMatchingFetchSpecification:t7fs];
    [self assertTrue:[t7results count]
                  && [[[t7results objectAtIndex:0] _cachedEntitiesForRelationshipNamed:"trunk"] count]
            message:"Prefetching of to-one relationship with no qualifiers"];

}

- (void) testPrefetchOfToManyWithNoQualifiers {
    var t11fs = [IFFetchSpecification new:"IFTestTrunk" :nil];
    [t11fs setPrefetchingRelationships:["branches"]];
    var t11results = [oc entitiesMatchingFetchSpecification:t11fs];
    [self assertTrue:([t11results count]
                   && [[[t11results objectAtIndex:0] _cachedEntitiesForRelationshipNamed:"branches"] count])
             message:"pre-fetching a to-many with no qualifiers"];
}

- (void) testTraversalOfTwoRelationshipsInQualifier {
    var t15fs = [IFFetchSpecification new:"IFTestRoot" :[IFKeyValueQualifier key:"trunk.branches.length = %@", 3]];
    var t15results = [oc entitiesMatchingFetchSpecification:t15fs];
    [self assert:[t15results count] equals:1 message:"Traversed 2 relationships with a single qualifier"];
}

- (void) testTraversalOfThreeRelationshipsInQualifier {
    var t16fs = [IFFetchSpecification new:"IFTestGround"
                                         :[IFKeyValueQualifier key:"root.trunk.branches.length = %@", 3]];
    var t16results = [oc entitiesMatchingFetchSpecification:t16fs];
    [self assert:[t16results count] equals:1 message:"Traverse three relationships with a single qualifier"];
    var t16fs = [IFFetchSpecification new:"IFTestRoot"
                                         :[IFKeyValueQualifier key:"trunk.branches.globules.name = %@", "Globule-0"]];
    var t16results = [oc entitiesMatchingFetchSpecification:t16fs];
    [self assert:[t16results count] equals:1 message:"Traverse 3 relationships, via m2m, with a single qualifier"];
}

- (void) testTraverseMultipleRelationshipsWithMultipleQualifiers {
    var t17fs = [IFFetchSpecification new:"IFTestRoot"
                        :[IFAndQualifier and:
                            [IFKeyValueQualifier key:"trunk.branches.globules.name = %@", "Globule-2"],
                            [IFKeyValueQualifier key:"ground.colour = %@", "Earthy brown"]
                        ]];
    var t17results = [oc entitiesMatchingFetchSpecification:t17fs];
    [self assert:[t17results count] equals:1 message:"Traversed multiple relationships with multiple qualifiers"];
}

- (void) testRepeatedJoins {
    var t20fs = [IFFetchSpecification new:"IFTestBranch"
                        :[IFAndQualifier and:[
                            [IFKeyValueQualifier key:"globules.name = %@", "Globule-0"],
                            [[IFKeyValueQualifier key:"globules.name = %@", "Globule-1"] requiresRepeatedJoin],
                        ]]];
    var t20results = [oc entitiesMatchingFetchSpecification:t20fs];
    [self assertTrue:([t20results count] > 0) message:"Found at least one branch that has globules 0 and 1"];
}

- (void) testQualifierWithoutBindValue {
    var rid = [root id];
    var t19fs = [IFFetchSpecification new:"IFTestRoot" :[IFKeyValueQualifier key:"id = " + rid]];
    var t19results = [oc entitiesMatchingFetchSpecification:t19fs];
    [self assert:[t19results count] equals:1 message:"Retrieved the correct number of roots without using bind value"];
}

@end
