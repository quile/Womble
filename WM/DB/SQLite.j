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

@import "../Object.j"
@import "Handle.j"

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
