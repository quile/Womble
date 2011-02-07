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


/* ------------------------------------------------
    Crappy DB methods; this stuff is old and nasty
   ------------------------------------------------ */

@import "WMApplication.j"
@import "WMArray.j"
@import "WMSQLStatement.j"
@import "DB/WMDBMySQL.j"
@import "DB/WMDBSQLite.j"
@import "WMConfig.j"

var UTIL = require("util");
var JDBC = require("jdbc");
var OS   = require("os");

var _connectionDictionary;
var _driver;
var _dbh;

@implementation WMDB : WMObject

+ updateRecord:(id)record inTable:(id)table {
    [self updateRecord:record inTable:table :"NOW"];
}

+ updateRecord:(id)record inTable:(id)table :(id)when {
    var dbh = [WMDB dbConnection];
    if (!dbh) {
        return null;
    }

    var id = [WMDB _valueForPrimaryKeyInRecord:record];
    var sql;

    if (id) {
        sql = [WMDB buildUpdateStatementForRecord:record inTable:table :dbh];
    } else {
        sql = [WMDB buildInsertStatementForRecord:record inTable:table :dbh :when];
    }
    // The driver should log it, so don't log it here.
    //[WMLog database:sql];

    /* execute it and grab the insert id if it's available */
    var rows = [[WMDB _driver] do:sql];

    if (typeof rows == "undefined") {
        [WMLog error:[[WMDB _driver] error] + " : " + sql];
    }

    if (!id) {
        id = [[WMDB _driver] lastInsertId];
        [WMDB _setValue:id forPrimaryKeyInRecord:record];
        [WMLog debug:"Inserted new record with ID " + id];
    }
}

+ buildInsertStatementForRecord:(id)record inTable:(id)table :(id)dbh :(id)when {

    var statement;
    if (when == "DELAYED") {
          statement = "INSERT DELAYED INTO " + table + " ";
      } else {
        statement = "INSERT INTO " + table + " ";
    }

    var keys = [WMArray new];
    var values = [WMArray new];
    var qms = [WMArray new];

    // record.CREATION_DATE = record.CREATION_DATE || [WMDateUnix new:time];
    // record.MODIFICATION_DATE = record.MODIFICATION_DATE || [WMDateUnix new:time];

    /* FIXME: this has to be able to use multiple models */
    /*
    var dm = [WMModel defaultModel];
    var ecd;
    if (dm) {
        ecd = [dm entityClassDescriptionForTable:table];
    }
    */
    var _ks = UTIL.sort(UTIL.keys(record));
    for (var i=0; i < _ks.length ; i++) {
        var key = _ks[i];
        if (key == "ID") { continue; }
        if (key.match(/^_/)) { continue; }
        if (!record[key]) { continue; }
        [keys addObject: '`' + key + '`'];
        var value = record[key];
        /*
        if (typeof value == "WMDateUnix" && ecd) {
            var attribute = [ecd attributeWithName:key];
            var at = attribute.TYPE;
            at = at.toUpperCase();
            if (at == "DATETIME" || at == "TIMESTAMP") {
                value = [value sqlDateTime];
            } else if (at == "INT") {
                value = [value utc];
            }
        }
        */
        //[values addObject:[dbh quote:value]];
        [values addObject:value];
        [qms addObject:"?"];
    }
    // FIXME rewrite to use bind values to avoid injection attacks
    var s = "INSERT INTO " + table + " (" + [keys componentsJoinedByString:", "] + ") VALUES (" + [qms componentsJoinedByString:", "] + ")";
    statement = [WMSQLStatement newWithSQL:s andBindValues:values];
    return statement;
}

+ buildUpdateStatementForRecord:(id)record inTable:(id)table :(id)dbh {
    var statement = "UPDATE " + table + " SET ";
    var id = [WMDB _valueForPrimaryKeyInRecord:record];
    //record.MODIFICATION_DATE = [WMDateUnix new];
    var keyValuePairs = [WMArray new];
    var keys = [WMArray new];
    var values = [WMArray new];

    /* lame */
    /*
    var dm = [WMModel defaultModel];
    var ecd;
    if (dm) {
        ecd = [dm entityClassDescriptionForTable:table];
    }
    */
    var _ks = UTIL.sort(UTIL.keys(record));
    for (var i=0; i < _ks.length ; i++) {
        var key = _ks[i];
        if (key == "ID") { continue; }
        if (key.match(/^_/)) { continue; };

        var value = record[key];

        /* hacky datefield nonsense */
        /*
        if (typeof value == "WMDateUnix" && ecd) {
            var attribute = [ecd attributeWithName:key];
            var at = attribute.TYPE;
            at = at.toUpperCase();
            if (at == "DATETIME" || at == "TIMESTAMP") {
                value = [value sqlDateTime];
            } else if (at == "INT") {
                value = [value utc];
            }
        }
        */

        [keys addObject:'`' + key + '`'];
        [values addObject:value];
        [keyValuePairs addObject: [keys lastObject] + " = ?"]
    }

    statement = statement + [keyValuePairs componentsJoinedByString:", "];
    statement = statement + " WHERE ID = ?";
    [values addObject: id];

    return [WMSQLStatement newWithSQL:statement andBindValues:values];
}

+ buildDeleteStatementForRecordWithPrimaryKey:(id)id inTable:(id)table {
    var sql = "DELETE FROM " + table + " WHERE ID = ?";
    var statement = [WMSQLStatement newWithSQL:sql andBindValues:[[WMArray alloc] initWithObjects:id]];
    return statement;
}

+ deleteRecord:(id)record fromTable:(id)table {
    var pk = [WMDB _valueForPrimaryKeyInRecord:record];
    if (pk) {
        var sql = [WMDB buildDeleteStatementForRecordWithPrimaryKey:pk inTable:table];
        [WMLog database:sql];
        var dbh = [WMDB dbConnection];
        if (!dbh) { return null; }
        var rows = [[WMDB _driver] do:sql];
        [WMLog database:rows + " row(s) deleted"];
    }
}

+ rawRowsForSQL:(id)sql {
    return [WMDB rawRowsForSQL:sql withBindValues:nil];
}

+ rawRowsForSQLStatement:(WMSQLStatement)st {
    return [WMDB rawRowsForSQL:[st sql] withBindValues:[st bindValues]];
}

+ rawRowsForSQL:(id)sql withBindValues:(id)bindValues {
    var results = [WMArray new];
    var dbh = [WMDB dbConnection]
    if (!dbh) { return results; }

    bindValues = bindValues || [WMArray new];

    [WMLog dump:bindValues];
    // not sure if this is necessary now, but it was
    // in perl because undefs were being filtered
    // out somewhere in the bowels of the DBI
    for (i=0; i<[bindValues count]; i++) {
        var v = [bindValues objectAtIndex:i];
        if (v == null) {
            [bindValues replaceObjectAtIndex:i withObject:''];
        }
    }

    //[WMLog database:"[" + sql + "]\n with bindings [" + [bindValues componentsJoinedByString:", "] + "]\n"];
    var results;
    var sth = [dbh prepare:sql];
    if (!sth) {
        [WMLog error:"[WMDB rawRowsForSQL] failed to prepare query: " + sql + " [" + bindValues + "] "];
        return null;
    }

    if ([sth executeWithBindValues:bindValues]) {
        var row;
        while (row = [sth nextResultAsDictionary]) {
            var keys = [row allKeys];
            for (var i=0; i<[keys count]; i++) {
                var k = [keys objectAtIndex:i];
                row[k.toUpperCase()] = row[k];
                if (!k.match(/^[A-Z0-9_]+$/)) {
                    delete row[k];
                }
            }
            results[results.length] = row;
        }
        [sth finish];
    } else {
        [WMLog error:"Error : " + sql];
    }
    [WMLog database:"Fetched " + [results count] + " row(s)\n"];
    return results;
}

+ executeArbitrarySQL:(id)sql {
    var dbh = [WMDB dbConnection];
    if (!dbh) {
        [WMLog error:"Failed to retrieve database connection"];
        return nil;
    }

    //[WMLog database:sql];
    var rows = [_driver do:sql];
    if (rows != 0) { [WMLog database:rows + " rows affected"] }
    return rows;
}

+ _driver {
    if (_driver) return _driver;
    var writeDefaultName = _connectionDictionary.DATA_SOURCE_CONFIG[WRITE_DEFAULT];
    var writeDefault = _connectionDictionary.DATA_SOURCES[writeDefaultName];
    if (writeDefault && writeDefault.dbString) {
        if (writeDefault.dbString =~ /SQLite/) {
            _driver = [WMDBSQLite new];
        }
    }
    _driver = _driver || [WMDBMySQL new];
    return _driver;
}

+ dbConnection {
    /* TODO: ping db here? */
    if (_dbh) { return _dbh };

    /* for now we just do write default */
    var wdName = _connectionDictionary.DATA_SOURCE_CONFIG['WRITE_DEFAULT'];
    var cInfo = _connectionDictionary.DATA_SOURCES[wdName];
    var cString = cInfo['dbString'];
    var dbh = JDBC.connect(cString);
    if (!dbh) {
        // explode!
        [WMLog error:"Couldn't connect to " + cString];
        OS.exit();
    }
    dbh.setAutoCommit(true);
    _dbh = [[WMDBHandle alloc] initWithHandle:dbh];
    if (cInfo && cString) {
        if (cString.match(/sqlite/)) {
            _driver = [[WMDBSQLite alloc] initWithHandle:_dbh];
        }
    }
    _driver = _driver || [[WMDBMySQL alloc] initWithHandle:_dbh];

    /* _dbh = [WMMultipleDataSourceAdaptor connectclassname :_connectionDictionary.DATA_SOURCES :                            _connectionDictionary->{DATA_SOURCE_CONFIG}](_connectionDictionary.DATA_SOURCES,
                            _connectionDictionary.DATA_SOURCE_CONFIG);
    */
    return _dbh;
}

+ releaseConnection {
    _dbh = null;
}

+ setDatabaseInformation:(id)dataSources :(id)dataSourceConfig {
    if (_connectionDictionary && _connectionDictionary.DATA_SOURCES) {
        [WMLog warning:"Overwriting existing connection dictionary information"];
    }
    [WMLog debug:"Updating data source information:"];
    [WMLog dump:dataSources];
    _connectionDictionary = {
        DATA_SOURCES: dataSources,
        DATA_SOURCE_CONFIG: dataSourceConfig,
    };
}

+ databaseInformation {
    return _connectionDictionary;
}

+ nextNumberForSequence:(id)sequenceName {
    return [[WMDB _driver] nextNumberForSequence:sequenceName];
}

+ tables {
    var dbh = [WMDB dbConnection];
    if (!dbh) return null;

    var rows = [WMDB rawRowsForSQL:"SHOW TABLES"];
    var tables = [];

    for (rowIndex in rows) {
        var row = rows[rowIndex];
        for (key in row) {
            if (!row[key]) continue;
            tables[tables.length] = row[key];
        }
    }
    return tables;
}

+ quote:(id)string {
    var dbh = [WMDB dbConnection];
    if (!dbh) return string;
    return [dbh quote:string];
}

+ descriptionOfTable:(id)tableName {
    if (!_driver) {
        [WMDB dbConnection];
    }
    return [[WMDB _driver] descriptionOfTable:tableName withHandle:dbh];
}

/* HACK: figure out the pk field of
   a record - only using this until
   we come up with a better way
   to do it.
*/

+ _valueForPrimaryKeyInRecord:(id)record {
    if (record.isa) {
        var ecd = [record entityClassDescription];
        if (ecd) {
            var pk = [ecd _primaryKey];
            if (pk) {
                return [pk valueForEntity:record];
            }
        }
    }
    return record['ID'];
}

+ _setValue:(id)value forPrimaryKeyInRecord:(id)record {
    if (record.isa) {
        var ecd = [record entityClassDescription];
        if (ecd) {
            var pk = [ecd _primaryKey];
            if (pk) {
                [pk setValue:value forEntity:record];
            }
        }
    }
    record['ID'] = value;
}

+ (void) startTransaction {
    [[WMDB _driver] startTransaction];
}

+ (void) endTransaction {
    [[WMDB _driver] endTransaction];
}

+ (void) rollbackTransaction {
    [[WMDB _driver] rollbackTransaction];
}

@end
