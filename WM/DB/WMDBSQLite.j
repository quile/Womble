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

@import "../WMObject.j"
@import "WMDBHandle.j"

@implementation WMDBSQLite : WMObject
{
    id wrappedHandle;
    id lastInsertId;
}

- initWithHandle:(id)h {
    [super init];
    wrappedHandle = h;
    lastInsertId = nil;
    return self;
}

- do:(id)st {
    /* insert statements need to be treated differently
       because we need to fetch back the rowid of the new
       row.
    */

    if (typeof st == "string") {
        st = [WMSQLStatement newWithSQL:st andBindValues:[]];
    }

    sql = [st sql];
    if (sql.match(/^insert/i)) {
        /* get the write default - we have to do this
           so we can get the last insert id back.
        */
        [wrappedHandle do:st];
        return 0;
    } else {
        return [wrappedHandle do:st];
    }
}

- descriptionOfTable:(id)tableName {
    var sql = "pragma table_info (" + tableName + ")";
    var results = [];
    var sth = [wrappedHandle prepare:sql];

    [sth execute];

    //if (dbh->errstr) {
    //    WMLog.error(dbh->errstr);
    //    return [];
    //}
    var result = nil;
    while (result = [sth nextResultAsArray]) {
        var index = [result objectAtIndex:0];
        var field = [result objectAtIndex:1];
        var type  = [result objectAtIndex:2];
        var what  = [result objectAtIndex:3];
        var def   = [result objectAtIndex:4];
        var isPk  = [result objectAtIndex:5];

        if (type == "INTEGER") {
            type = "INT(11)";
        }
        var col = {
            FIELD: field,
            TYPE: type,
            DEFAULT: def,
        };
        results[results.length] = col;
    }
    return results;
}

- lastInsertId {
    return [wrappedHandle lastInsertId];
}

- countUsingSQL:(id)sqst {
    var sth = [wrappedHandle prepare:[sqst sql]];
    var bvs = [sqst bindValues] || [WMArray new];
    [sth executeWithBindValues:bvs];

    //if (dbh->errstr) {
    //    WMLog.error(dbh->errstr);
    //    return 0;
    //}

    var row = [sth nextResultAsArray];
    [sth close];
    var count = [row objectAtIndex:0];
    if (typeof count != "undefined") {
        return count - 0;
    }
    return 0;
}

- nextNumberForSequence:(id)sequenceName {
    var nextId;
    if (!wrappedHandle) { return null; }

    var sequenceTable = [WMApplication systemConfigurationValueForKey:"SEQUENCE_TABLE"];

    var sth = [wrappedHandle prepare:"SELECT NEXT_ID FROM " + sequenceTable + " WHERE NAME = ?"];
    if ([sth executeWithBindValues:[[WMArray alloc] initWithObjects:sequenceName]]) {
        var nextId = [[sth nextResultAsArray] objectAtIndex:0];
        [sth finish];
        if (!nextId) {
            [wrappedHandle do:[WMSQLStatement newWithSQL:"INSERT INTO " + sequenceTable + " (NAME, NEXT_ID) VALUES (?, ?)" andBindValues:[[WMArray alloc] initWithObjects:sequenceName, 1]]];
            nextId = 1;
        }
        [wrappedHandle do:[WMSQLStatement newWithSQL:"UPDATE " + sequenceTable + " SET NEXT_ID=NEXT_ID+1 WHERE NAME=?" andBindValues:[[WMArray alloc] initWithObjects:sequenceName]]];
    }
    return nextId;
}

// ?
- error {
    return "";
}

- (void) startTransaction {
    var st = [WMSQLStatement newWithSQL:"BEGIN;" andBindValues:[]];
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
