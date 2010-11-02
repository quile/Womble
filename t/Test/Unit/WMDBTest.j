/* --------------------------------------------------------------------
 * WM - Web Framework and ORM heavily influenced by WebObjects & EOF
 * (C) kd 2010
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
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
