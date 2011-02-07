/* --------------------------------------------------------------------
 * WM - Web Framework and ORM heavily influenced by WebObjects & EOF
 * The MIT License
 *
 * Copyright (c) 2010 kd
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

@import <OJUnit/OJTestCase.j>
@import <WM/WMDB.j>
@import <WM/WMApplication.j>
@import "../../Application.j"
@import "../../Entity/Ground.j"

application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation WMDBTest : OJTestCase

- (void) testBuildInsert
{
    var record = {
        COLOUR: "blue",
        AMOUNT: 12.5,
        SOME_TEXT: "foo bar baz"
    };
    var insert = [WMDB buildInsertStatementForRecord:record inTable:"SOME_TABLE" :null :null];
    [self assert:[insert sql] equals:'INSERT INTO SOME_TABLE (`AMOUNT`, `COLOUR`, `SOME_TEXT`) VALUES (?, ?, ?)'];
    [self assert:[insert bindValues] equals:[[WMArray alloc] initWithObjects:12.5, "blue", "foo bar baz"]];
}

- (void) testBuildUpdate
{
    var record = {
        ID: 12,
        COLOUR: "blue",
        AMOUNT: 12.5,
        SOME_TEXT: "foo bar baz"
    };
    var update = [WMDB buildUpdateStatementForRecord:record inTable:"SOME_TABLE" :null];
    [self assert:[update sql] equals:@"UPDATE SOME_TABLE SET `AMOUNT` = ?, `COLOUR` = ?, `SOME_TEXT` = ? WHERE ID = ?"];
    [self assert:[update bindValues] equals:[[WMArray alloc] initWithObjects:12.5, "blue", "foo bar baz", 12]];
}

- (void) testBuildDelete {
    var del = [WMDB buildDeleteStatementForRecordWithPrimaryKey:12 inTable:"SOME_TABLE"];
    [self assert:[del sql] equals:"DELETE FROM SOME_TABLE WHERE ID = ?"];
    [self assert:[del bindValues] equals:[[WMArray alloc] initWithObjects:12]];
}

- (void) testConnect {
    var dbh = [WMDB dbConnection];
    [self assertNotNull:dbh message:"db handle retrieved"];
}

- (void) testExecute {
    var dbh = [WMDB dbConnection];
    [self assertNotNull:dbh];
    var statement = [WMSQLStatement newWithSQL:[WMTestGround _test_createTableCommand]
                                 andBindValues:[]];

    var driver = [WMDB _driver];
    [self assertNotNull:driver message:"Driver seems to be working"];
    // create the table
    [driver do:statement];

    // check table
    var description = [driver descriptionOfTable:"GROUND"];
    [self assert:description.length equals:4 message:"Correct meta info for table found"];

    statement = [WMSQLStatement newWithSQL:[WMTestGround _test_dropTableCommand]
                                 andBindValues:[]];

    // drop the table
    [driver do:statement];

}

- (void) testFetchRow {
    var statement = [WMSQLStatement newWithSQL:[WMTestGround _test_createTableCommand]
                                 andBindValues:[]];

    var driver = [WMDB _driver];

    // create the table
    [driver do:statement];

    // test fetching

    [driver do:[WMSQLStatement newWithSQL:"INSERT INTO GROUND (CREATION_DATE, MODIFICATION_DATE, COLOUR) VALUES ('2000-01-01 00:00:00', '2000-01-01 00:00:00', 'GREEN')" andBindValues:[]]];

    var lastInsertId = [driver lastInsertId];

    var results = [driver do:[WMSQLStatement newWithSQL:"SELECT ID AS FOO, CREATION_DATE AS BAR, MODIFICATION_DATE AS BAZ, COLOUR AS COL FROM GROUND WHERE ID = ?" andBindValues:[lastInsertId]]];

    [self assertNotNull:results];
    [self assertTrue:(results.isa && [results isKindOfClass:CPArray]) message:"Array of results came back"];
    [self assert:[[results objectAtIndex:0] objectForKey:"COL"] equals:"GREEN" message:"Retrieved dictionary as result"];

    [self assert:[driver countUsingSQL:[WMSQLStatement newWithSQL:"SELECT COUNT(*) AS C FROM GROUND" andBindValues:[]]] equals:1];

    var rows = [WMDB rawRowsForSQL:"SELECT * FROM GROUND"];
    [self assert:[rows count] equals:1];

    var rows = [WMDB rawRowsForSQL:"SELECT * FROM GROUND WHERE ID=?" withBindValues:[1]];
    [self assert:[rows count] equals:1];

    var rows = [WMDB rawRowsForSQL:"SELECT * FROM GROUND WHERE ID=? AND COLOUR=?" withBindValues:[1, "GREEN"]];
    [self assert:[rows count] equals:1];

    var rows = [WMDB rawRowsForSQL:"SELECT * FROM GROUND WHERE 1=0"];
    [self assert:[rows count] equals:0];

    // drop the table
    [driver do:
        [WMSQLStatement newWithSQL:[WMTestGround _test_dropTableCommand] andBindValues:[]]];
}

- (void) testSequences {
    var driver = [WMDB _driver];
    [driver do:[WMSQLStatement newWithSQL:"CREATE TABLE SEQUENCE (NAME VARCHAR(32), NEXT_ID INT(11))" andBindValues:[]]];

    var seq = [driver nextNumberForSequence:"FOO"];
    [self assert:seq equals:1 message:"Sequence initialised"];
    seq = [driver nextNumberForSequence:"FOO"];
    [self assert:seq equals:2 message:"Sequence incremented"];
    var seq2 = [driver nextNumberForSequence:"BAR"];
    [self assert:seq2 equals:1 message:"Second sequence initialised"];
    seq = [driver nextNumberForSequence:"FOO"];
    [self assert:seq equals:3 message:"First sequence incremented correctly"];

    [driver do:[WMSQLStatement newWithSQL:"DROP TABLE IF EXISTS `SEQUENCE`" andBindValues:nil]];
}

@end
