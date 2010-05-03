@import <OJUnit/OJTestCase.j>
@import <IF/Application.j>
@import <IF/Model.j>
@import <IF/EntityClassDescription.j>
@import <IF/SQLExpression.j>
@import "../../Application.j"

var UTIL = require("util");

application = [IFApplication applicationInstanceWithName:"IFTest"];

@implementation IFSQLExpressionTest : OJTestCase

- (void) testInit {
    var s = [IFSQLExpression new];
    [self assertTrue:(s && [s fetchLimit] == nil) message:"Seems initialised OK"];
}

- (void) testTables {
    var s = [IFSQLExpression new];

    // for now s has mostly pure JS properties
    [self assert:UTIL.keys([s tables]).length equals:0 message:"Table count seems correct"];
    [s addTable:"GROUND"];
    [self assert:UTIL.keys([s tables]).length equals:1 message:"Table count seems correct"];
    [s addTable:"FOO"];
    [self assert:UTIL.keys([s tables]).length equals:2 message:"Table count seems correct"];
    [s addTable:"GROUND"];
    // make sure adding a table twice doesn't do anything
    [self assert:UTIL.keys([s tables]).length equals:2 message:"Table count seems correct"];

    [self assert:[s tablesAsSQL] equals:"FOO T1, GROUND T0" message:"SQL correct"];

    // remove a table
    [s removeTableWithName:"GROUND"];
    [self assert:[s tablesAsSQL] equals:"FOO T1" message:"SQL correct"];
}

- (void) testRepeatedJoins {
    var s = [IFSQLExpression new];

    [s addTable:"FOO"];
    [s addTable:"BAR"];
    [s addRepeatedTable:"FOO"];

    [self assert:[s tablesAsSQL] equals:"BAR T1, FOO T0, FOO T2" message:"SQL correct"];
}


- (void) testEntityClassDescriptions {
    var s = [IFSQLExpression new];
    var m = [IFModel defaultModel];

    [self assertNotNull:m message:"Model is not null"];
    var root = [m entityClassDescriptionForEntityNamed:"IFTestRoot"];
    var ground = [m entityClassDescriptionForEntityNamed:"IFTestGround"];
    [self assertNotNull:root message:"Got root"];
    [self assertNotNull:ground message:"Got ground"];

    [s addEntityClassDescription:ground];
    [s addEntityClassDescription:root];

    [s addTraversedRelationship:[root relationshipWithName:"ground"] onEntity:root :true];
    [self assert:[s tablesAsSQL] equals:"GROUND T0, ROOT T1" message:"Correct table SQL generated"];
    [s addTableToFetch:"GROUND"];
    [self assert:[s columnsAsSQL] equals:"T0.ID AS T0_ID, T0.CREATION_DATE AS T0_CREATION_DATE, T0.COLOUR AS T0_COLOUR, T0.MODIFICATION_DATE AS T0_MODIFICATION_DATE" message:"Correct column SQL generated"];

    [s setSortOrderings:["roots.id"]];
    [self assert:[s sortOrderingsAsSQL] equals:"T1.ID" message:"Ordering is correct"];

    [s setSortOrderings:["roots.trunk.id"]];
    [self assert:[s sortOrderingsAsSQL] equals:"T2.ID" message:"Ordering is correct"];

    [s setSortOrderings:["roots.trunk.branches.id"]];
    [self assert:[s sortOrderingsAsSQL] equals:"T3.ID" message:"Ordering is correct"];
}

@end
