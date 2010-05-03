/* --------------------------------------------------------------------
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


/* ------------------------------------------------
    Crappy DB methods; this stuff is old and nasty
   ------------------------------------------------ */

@import "Application.j"
@import "Array.j"
@import "SQLStatement.j"
@import "DB/MySQL.j"
@import "DB/SQLite.j"
@import "Config.j"

var UTIL = require("util");
var JDBC = require("jdbc");
var OS   = require("os");

var _connectionDictionary;
var _driver;
var _dbh;

@implementation IFDB : IFObject

+ updateRecord:(id)record inTable:(id)table {
    [self updateRecord:record inTable:table :"NOW"];
}

+ updateRecord:(id)record inTable:(id)table :(id)when {
	var dbh = [IFDB dbConnection];
	if (!dbh) {
        return null;
    }

	var id = [IFDB _valueForPrimaryKeyInRecord:record];
	var sql;

	if (id) {
		sql = [IFDB buildUpdateStatementForRecord:record inTable:table :dbh];
	} else {
		sql = [IFDB buildInsertStatementForRecord:record inTable:table :dbh :when];
	}
    // The driver should log it, so don't log it here.
	//[IFLog database:sql];

	/* execute it and grab the insert id if it's available */
	var rows = [[IFDB _driver] do:sql];

	if (typeof rows == "undefined") {
		[IFLog error:[[IFDB _driver] error] + " : " + sql];
	}

	if (!id) {
	    id = [[IFDB _driver] lastInsertId];
		[IFDB _setValue:id forPrimaryKeyInRecord:record];
		[IFLog debug:"Inserted new record with ID " + id];
	}
}

+ buildInsertStatementForRecord:(id)record inTable:(id)table :(id)dbh :(id)when {

	var statement;
	if (when == "DELAYED") {
  		statement = "INSERT DELAYED INTO " + table + " ";
  	} else {
        statement = "INSERT INTO " + table + " ";
    }

    var keys = [IFArray new];
	var values = [IFArray new];
    var qms = [IFArray new];

	// record.CREATION_DATE = record.CREATION_DATE || [IFDateUnix new:time];
	// record.MODIFICATION_DATE = record.MODIFICATION_DATE || [IFDateUnix new:time];

    /* FIXME: this has to be able to use multiple models */
    /*
    var dm = [IFModel defaultModel];
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
		if (typeof value == "IFDateUnix" && ecd) {
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
    statement = [IFSQLStatement newWithSQL:s andBindValues:values];
    return statement;
}

+ buildUpdateStatementForRecord:(id)record inTable:(id)table :(id)dbh {
	var statement = "UPDATE " + table + " SET ";
	var id = [IFDB _valueForPrimaryKeyInRecord:record];
    //record.MODIFICATION_DATE = [IFDateUnix new];
    var keyValuePairs = [IFArray new];
    var keys = [IFArray new];
	var values = [IFArray new];

    /* lame */
    /*
    var dm = [IFModel defaultModel];
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
		if (typeof value == "IFDateUnix" && ecd) {
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

	return [IFSQLStatement newWithSQL:statement andBindValues:values];
}

+ buildDeleteStatementForRecordWithPrimaryKey:(id)id inTable:(id)table {
	var sql = "DELETE FROM " + table + " WHERE ID = ?";
    var statement = [IFSQLStatement newWithSQL:sql andBindValues:[[IFArray alloc] initWithObjects:id]];
	return statement;
}

+ deleteRecord:(id)record fromTable:(id)table {
	var pk = [IFDB _valueForPrimaryKeyInRecord:record];
	if (pk) {
		var sql = [IFDB buildDeleteStatementForRecordWithPrimaryKey:pk inTable:table];
		[IFLog database:sql];
		var dbh = [IFDB dbConnection];
		if (!dbh) { return null; }
		var rows = [[IFDB _driver] do:sql];
		[IFLog database:rows + " row(s) deleted"];
	}
}

+ rawRowsForSQL:(id)sql {
	return [IFDB rawRowsForSQL:sql withBindValues:nil];
}

+ rawRowsForSQLStatement:(IFSQLStatement)st {
    return [IFDB rawRowsForSQL:[st sql] withBindValues:[st bindValues]];
}

+ rawRowsForSQL:(id)sql withBindValues:(id)bindValues {
    var results = [IFArray new];
	var dbh = [IFDB dbConnection]
    if (!dbh) { return results; }

    bindValues = bindValues || [IFArray new];

    [IFLog dump:bindValues];
    // not sure if this is necessary now, but it was
    // in perl because undefs were being filtered
    // out somewhere in the bowels of the DBI
    for (i=0; i<[bindValues count]; i++) {
        var v = [bindValues objectAtIndex:i];
        if (v == null) {
            [bindValues replaceObjectAtIndex:i withObject:''];
        }
    }

	//[IFLog database:"[" + sql + "]\n with bindings [" + [bindValues componentsJoinedByString:", "] + "]\n"];
	var results;
	var sth = [dbh prepare:sql];
	if (!sth) {
		[IFLog error:"[IFDB rawRowsForSQL] failed to prepare query: " + sql + " [" + bindValues + "] "];
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
		[IFLog error:"Error : " + sql];
	}
	[IFLog database:"Fetched " + [results count] + " row(s)\n"];
	return results;
}

+ executeArbitrarySQL:(id)sql {
	var dbh = [IFDB dbConnection];
    if (!dbh) {
        [IFLog error:"Failed to retrieve database connection"];
        return nil;
    }

	//[IFLog database:sql];
	var rows = [_driver do:sql];
    if (rows != 0) { [IFLog database:rows + " rows affected"] }
	return rows;
}

+ _driver {
    if (_driver) return _driver;
    var writeDefaultName = _connectionDictionary.DATA_SOURCE_CONFIG[WRITE_DEFAULT];
	var writeDefault = _connectionDictionary.DATA_SOURCES[writeDefaultName];
	if (writeDefault && writeDefault.dbString) {
	    if (writeDefault.dbString =~ /SQLite/) {
	        _driver = [IFDBSQLite new];
	    }
	}
	_driver = _driver || [IFDBMySQL new];
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
        [IFLog error:"Couldn't connect to " + cString];
        OS.exit();
    }
    dbh.setAutoCommit(true);
    _dbh = [[IFDBHandle alloc] initWithHandle:dbh];
    if (cInfo && cString) {
        if (cString.match(/sqlite/)) {
            _driver = [[IFDBSQLite alloc] initWithHandle:_dbh];
        }
    }
    _driver = _driver || [[IFDBMySQL alloc] initWithHandle:_dbh];

    /* _dbh = [IFMultipleDataSourceAdaptor connectclassname :_connectionDictionary.DATA_SOURCES :							_connectionDictionary->{DATA_SOURCE_CONFIG}](_connectionDictionary.DATA_SOURCES,
							_connectionDictionary.DATA_SOURCE_CONFIG);
    */
	return _dbh;
}

+ releaseConnection {
    _dbh = null;
}

+ setDatabaseInformation:(id)dataSources :(id)dataSourceConfig {
	if (_connectionDictionary && _connectionDictionary.DATA_SOURCES) {
		[IFLog warning:"Overwriting existing connection dictionary information"];
	}
    [IFLog debug:"Updating data source information:"];
    [IFLog dump:dataSources];
	_connectionDictionary = {
		DATA_SOURCES: dataSources,
		DATA_SOURCE_CONFIG: dataSourceConfig,
	};
}

+ databaseInformation {
    return _connectionDictionary;
}

+ nextNumberForSequence:(id)sequenceName {
    return [[IFDB _driver] nextNumberForSequence:sequenceName];
}

+ tables {
	var dbh = [IFDB dbConnection];
    if (!dbh) return null;

	var rows = [IFDB rawRowsForSQL:"SHOW TABLES"];
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
	var dbh = [IFDB dbConnection];
    if (!dbh) return string;
	return [dbh quote:string];
}

+ descriptionOfTable:(id)tableName {
    if (!_driver) {
        [IFDB dbConnection];
    }
    return [[IFDB _driver] descriptionOfTable:tableName withHandle:dbh];
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

@end
