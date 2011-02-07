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

@import "../WMDictionary.j";
@import "../WMDB.j";

@implementation WMDBMySQL : WMDictionary
{
}

- initWithHandle:(id)h {
    [super init];
    wrappedHandle = h;
    lastInsertId = nil;
    return self;
}

- do:(id)sql {
    return [dbh do:sql];
}

- descriptionOfTable:(id)tableName {
    var sql = "SHOW COLUMNS FROM " + tableName;
    return [WMDB rawRowsForSQL:sql];
}

- lastInsertId {
    return [wrappedHandle lastInsertId];
}

- countUsingSql:(id)sql {
    return [WMDB rawRowsForSQL:sql];
}

- nextNumberForSequence:(id)sequenceName {
    var nextId;
    if (!wrappedHandle) { return null; }

    var sequenceTable = [WMApplication systemConfigurationValueForKey:"SEQUENCE_TABLE"];
    var sth = [wrappedHandle prepare:"LOCK TABLES " + sequenceTable + " WRITE"];
    if ([sth execute]) {
        var fsth = [wrappedHandle prepare:"SELECT NEXT_ID FROM " + sequenceTable + " WHERE NAME = ?"];
        if ([fsth executeWithBindValues:[sequenceName]]) {
            var nextId = [[sth nextResultAsArray] objectAtIndex:0];
            [fsth finish];
            if (!nextId) {
                [wrappedHandle do:[WMSQLStatement newWithSQL:"INSERT INTO " + sequenceTable + " (NAME, NEXT_ID) VALUES (?, ?)" andBindValues:[[WMArray alloc] initWithObjects:sequenceName, 1]]];
                nextId = 1;
            }

            [wrappedHandle do:[WMSQLStatement newWithSQL:"UPDATE " + sequenceTable + " SET NEXT_ID=NEXT_ID+1 WHERE NAME=?" andBindValues:[[WMArray alloc] initWithObjects:sequenceName]]];
            [wrappedHandle do:"UNLOCK TABLES"];
        }
        [sth finish];
    }
    return nextId;
}

- (void) startTransaction {
    var st = [WMSQLStatement newWithSQL:"SET autocommit = 0" andBindValues:[]];
    [wrappedHandle do:st];
    var st = [WMSQLStatement newWithSQL:"BEGIN" andBindValues:[]];
    [wrappedHandle do:st];
}

- (void) endTransaction {
    var st = [WMSQLStatement newWithSQL:"COMMIT;" andBindValues:[]];
    [wrappedHandle do:st];
}

- (void) rollbackTransaction {
    var st = [WMSQLStatement newWithSQL:"ROLLBACK;" andBindValues:[]];
    [wrappedHandle do:st];
}

@end
