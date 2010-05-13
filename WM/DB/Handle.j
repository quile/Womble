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

@import <Foundation/CPException.j>
@import "../Object.j"

// uber-soft implementation of the perl DBI to
// assist in porting

@implementation WMDBException : CPException
// ?
@end

@implementation WMDBStatement : WMObject
{
    id statement; // JDBC statement
    id results; // JDBC result set
    id sql;
    id wrappedHandle;
}

- initWithJDBCStatement:(id)st SQL:sq handle:h {
    [super init];
    statement = st;
    sql = sq;
    wrappedHandle = h;
    return self;
}

- execute {
    [self executeWithBindValues:nil];
}

- executeWithBindValues:(id)bvs {
    if (!bvs) { bvs = [WMArray new]; }
    //[WMLog dump:bvs];
    //[WMLog debug:"SQL " + sql + " BVS " + bvs];
    for (var i=0; i<[bvs count]; i++) {
        // FIXME should use setObject and let java do the mapping
        statement.setString(i + 1, [bvs objectAtIndex:i]);
    }
    // hmmpf

    var log = sql;
    if ([bvs count]) { log += " (" + bvs + ")" }
    [WMLog database:log];
    // fire off an update
    var hasResults = statement.execute();
    var keys = statement.getGeneratedKeys();

    // find the last insert id if there was one
    // and push it into the handle.
    var lastInsertId = null;
    if (keys.next()) {
        lastInsertId = keys.getInt(1);
    }
    keys.close();
    [wrappedHandle setLastInsertId:lastInsertId];

    if (hasResults) {
        results = statement.getResultSet();
        return hasResults;
    } else {
        results = null;
        //return statement.getUpdateCount();
        return true;
    }
    return false;
}

// $sth->fetchrow_arrayref()
- nextResultAsArray {
    if (!results) { return nil; }
    var n = results.next();
    if (!n) { return nil; }
    var rsm = results.getMetaData();
    var columnCount = rsm.getColumnCount();
    var result = [WMArray new];
    for (var i=0; i<columnCount; i++) {
        [result addObject:results.getObject(i+1)];
    }
    return result;
}

// $sth->fetchrow_hashref()
- nextResultAsDictionary {
    if (!results) { return nil; }
    var n = results.next();
    if (!n) { return nil; }
    var rsm = results.getMetaData();
    var columnCount = rsm.getColumnCount();
    var result = [WMDictionary new];
    for (var i=0; i<columnCount; i++) {
        [result setObject:results.getObject(i+1) forKey:rsm.getColumnName(i+1)];
    }
    return result;
}

// $sth->finish();
- finish {
    [self close];
}

- close {
    if (statement) { statement.close(); }
    wrappedHandle = nil;
}

@end

@implementation WMDBHandle : WMObject
{
    id dbh; // JDBC handle
    id lastInsertId @accessors;
}

- initWithHandle:(id)handle {
    [super init];
    dbh = handle;
    return self;
}

- prepare:(id)sql {
    if (!dbh) { throw [CPException raise:WMDBException reason:"No database handle"]; }
    try {
        var st = dbh.prepareStatement(sql);
        return [[WMDBStatement alloc] initWithJDBCStatement:st SQL:sql handle:self];
    } catch (e) {
        [WMLog error:"Failed to prepare SQL: " + sql];
        throw e;
    }
    return nil;
}

- do:(id)sqst {
    if (!dbh) { throw [CPException raise:WMDBException reason:"No database handle"]; }
    var st = [self prepare:[sqst sql]];
    if (st) {
        var rows = [st executeWithBindValues:[sqst bindValues]];
        var results = [WMArray new];
        var result;
        while (result = [st nextResultAsDictionary]) {
            [results addObject:result];
        }
        [st close];
        return results || rows;
    }
    return nil;
}

@end
