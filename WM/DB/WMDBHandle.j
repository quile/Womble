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

@import <Foundation/CPException.j>
@import "../WMObject.j"

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
