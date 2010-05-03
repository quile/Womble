@import <OJUnit/OJTestCase.j>
@import <IF/DB.j>
@import <IF/Application.j>
@import "../../Application.j"
@import "../../Entity/Ground.j"

application = [IFApplication applicationInstanceWithName:"IFTest"];

@implementation IFDBTest : OJTestCase

- (void) testBuildInsert
{
    var record = {
        COLOUR: "blue",
        AMOUNT: 12.5,
        SOME_TEXT: "foo bar baz"
    };
    var insert = [IFDB buildInsertStatementForRecord:record inTable:"SOME_TABLE" :null :null];
    [self assert:[insert sql] equals:'INSERT INTO SOME_TABLE (`AMOUNT`, `COLOUR`, `SOME_TEXT`) VALUES (?, ?, ?)'];
    [self assert:[insert bindValues] equals:[[IFArray alloc] initWithObjects:12.5, "blue", "foo bar baz"]];
}

- (void) testBuildUpdate
{
    var record = {
        ID: 12,
        COLOUR: "blue",
        AMOUNT: 12.5,
        SOME_TEXT: "foo bar baz"
    };
    var update = [IFDB buildUpdateStatementForRecord:record inTable:"SOME_TABLE" :null];
    [self assert:[update sql] equals:@"UPDATE SOME_TABLE SET `AMOUNT` = ?, `COLOUR` = ?, `SOME_TEXT` = ? WHERE ID = ?"];
    [self assert:[update bindValues] equals:[[IFArray alloc] initWithObjects:12.5, "blue", "foo bar baz", 12]];
}

- (void) testBuildDelete {
    var del = [IFDB buildDeleteStatementForRecordWithPrimaryKey:12 inTable:"SOME_TABLE"];
    [self assert:[del sql] equals:"DELETE FROM SOME_TABLE WHERE ID = ?"];
    [self assert:[del bindValues] equals:[[IFArray alloc] initWithObjects:12]];
}

- (void) testConnect {
    var dbh = [IFDB dbConnection];
    [self assertNotNull:dbh message:"db handle retrieved"];
}

- (void) testExecute {
    var dbh = [IFDB dbConnection];
    [self assertNotNull:dbh];
    var statement = [IFSQLStatement newWithSQL:[IFTestGround _test_createTableCommand]
                                 andBindValues:[]];

    var driver = [IFDB _driver];
    [self assertNotNull:driver message:"Driver seems to be working"];
    // create the table
    [driver do:statement];

    // check table
    var description = [driver descriptionOfTable:"GROUND"];
    [self assert:description.length equals:4 message:"Correct meta info for table found"];

    statement = [IFSQLStatement newWithSQL:[IFTestGround _test_dropTableCommand]
                                 andBindValues:[]];

    // drop the table
    [driver do:statement];

}

- (void) testFetchRow {
    var statement = [IFSQLStatement newWithSQL:[IFTestGround _test_createTableCommand]
                                 andBindValues:[]];

    var driver = [IFDB _driver];

    // create the table
    [driver do:statement];

    // test fetching

    [driver do:[IFSQLStatement newWithSQL:"INSERT INTO GROUND (CREATION_DATE, MODIFICATION_DATE, COLOUR) VALUES ('2000-01-01 00:00:00', '2000-01-01 00:00:00', 'GREEN')" andBindValues:[]]];

    var lastInsertId = [driver lastInsertId];

    var results = [driver do:[IFSQLStatement newWithSQL:"SELECT ID AS FOO, CREATION_DATE AS BAR, MODIFICATION_DATE AS BAZ, COLOUR AS COL FROM GROUND WHERE ID = ?" andBindValues:[lastInsertId]]];

    [self assertNotNull:results];
    [self assertTrue:(results.isa && [results isKindOfClass:CPArray]) message:"Array of results came back"];
    [self assert:[[results objectAtIndex:0] objectForKey:"COL"] equals:"GREEN" message:"Retrieved dictionary as result"];

    [self assert:[driver countUsingSQL:[IFSQLStatement newWithSQL:"SELECT COUNT(*) AS C FROM GROUND" andBindValues:[]]] equals:1];

    var rows = [IFDB rawRowsForSQL:"SELECT * FROM GROUND"];
    [self assert:[rows count] equals:1];

    var rows = [IFDB rawRowsForSQL:"SELECT * FROM GROUND WHERE ID=?" withBindValues:[1]];
    [self assert:[rows count] equals:1];

    var rows = [IFDB rawRowsForSQL:"SELECT * FROM GROUND WHERE ID=? AND COLOUR=?" withBindValues:[1, "GREEN"]];
    [self assert:[rows count] equals:1];

    var rows = [IFDB rawRowsForSQL:"SELECT * FROM GROUND WHERE 1=0"];
    [self assert:[rows count] equals:0];

    // drop the table
    [driver do:
        [IFSQLStatement newWithSQL:[IFTestGround _test_dropTableCommand] andBindValues:[]]];
}

- (void) testSequences {
    var driver = [IFDB _driver];
    [driver do:[IFSQLStatement newWithSQL:"CREATE TABLE SEQUENCE (NAME VARCHAR(32), NEXT_ID INT(11))" andBindValues:[]]];

    var seq = [driver nextNumberForSequence:"FOO"];
    [self assert:seq equals:1 message:"Sequence initialised"];
    seq = [driver nextNumberForSequence:"FOO"];
    [self assert:seq equals:2 message:"Sequence incremented"];
    var seq2 = [driver nextNumberForSequence:"BAR"];
    [self assert:seq2 equals:1 message:"Second sequence initialised"];
    seq = [driver nextNumberForSequence:"FOO"];
    [self assert:seq equals:3 message:"First sequence incremented correctly"];

    [driver do:[IFSQLStatement newWithSQL:"DROP TABLE IF EXISTS `SEQUENCE`" andBindValues:nil]];
}

@end
