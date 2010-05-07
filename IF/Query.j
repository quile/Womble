/* --------------------------------------------------------------------
 * IF - Web Framework and ORM heavily influenced by WebObjects & EOF
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


@import <IF/DB.j>
@import <IF/Log.j>
@import <IF/Array.j>
@import <IF/ObjectContext.j>
@import <IF/Entity/Transient.j>

@implementation IFQuery : IFTransientEntity
{
    id _entity;
    id _dbh;
    id _qualifiers;
    id _sth;
    id _fetchLimit;
    id _fetchCount;
    id _startIndex;
    id _sortOrderings;
    id _prefetchingRelationships;
    id _readAhead;
    id _isComplete;
    id _oc;
}

+ new:(id)ecn {
    var q = [self alloc];
    [q setEntity:ecn];
    return [q init];
}

- init {
    [super init];
    _dbh = [IFDB dbConnection];
    _qualifiers = [];
    _sth = null;
    _fetchLimit = 0;
    _fetchCount = 0;
    _startIndex = 0;
    _sortOrderings = [];
    _prefetchingRelationships = [];
    _readAhead = null;
    _isComplete = 0;
    // a query needs to keep a handle to the OC
    _oc = [IFObjectContext new];
    return self;
}

- reset {
    _isComplete = 0;
    _sth = null;
    _fs  = null;
    _readAhead = null;
    _fetchCount = 0;
    return self;
}

- limit:(id)limit {
    _fetchLimit = limit;
    return [self _me];
}

- offset:(id)offset {
    _startIndex = offset;
    return [self _me];
}

- orderBy:(id)orderBy {
    orderBy = [IFArray arrayFromObject:orderBy];
    _sortOrderings = orderBy;
    return [self _me];
}

- prefetch:(id)relationship {
    relationship = [IFArray arrayFromObject:relationship];
    [_prefetchingRelationships addObjectsFromArray:relationship];
    return [self _me];
}

- filter:(id)condition, ... {
    var q;
    var bindValues = [IFArray new];
    for (var i=3; arguments[i] != nil; i++) {
        [bindValues addObject:arguments[i]];
    }
    q = [IFKeyValueQualifier key:condition bindValues:bindValues];
    [_qualifiers addObject:q];
    return [self _me];
}

- qualifier:(id)q {
    [_qualifier addObject:q];
    return [self _me];
}

- fetchSpecification {
    var q = [IFAndQualifier and:_qualifiers];
    var fs = [IFFetchSpecification new:_entity :q];
    //[IFLog debug:fs];
    [fs setFetchLimit:nil];
    [fs setStartIndex:_startIndex];
    [fs setSortOrderings:_sortOrderings];
    /* You can't prefetch if you are using startIndex. */
    if (!_startIndex) {
        [fs setPrefetchingRelationships:_prefetchingRelationships];
    }
    return fs;
}

- _execute {
    var fs = [self fetchSpecification];
    if (!fs) { return }
    _fs = fs;
    _sth = [self _statementHandleForSqlExpression:[fs toSQLFromExpression]];
}

/* This is mostly duplicated from IF::DB; it should
   get folded back in there ultimately.
*/
- _statementHandleForSqlExpression:(id)sqlExpression {
    var sql = [sqlExpression sql];

    var bindValues = [sqlExpression bindValues] || [];
    /* In-place filter them to change undefs into empty strings. */
    //foreach var bv (@bindValues) {
    //    if (!defined(bv)) {
    //        bv = '';
    //    }
    //    }
    [IFLog database:"[" + sql + "] with bindings [" + bindValues.join(", ") + "]"];
    var sth = [_dbh prepare:sql];
    if (!sth) {
        [IFLog error:self + " failed to prepare query: " + sql];
        return nil;
    }
    var rv;
    if (rv = [sth executeWithBindValues:bindValues]) {
        return sth;
    }
    [IFLog warning:"Failed to execute query " + sql];
    return nil;
}

- _close {
    if (_sth) {
        [_sth finish];
    }
    _isComplete = 1; // I hate this.
    _readAhead = nil;
}

/* we could always make this a shallow copier if we want,
   rather than have it mutate the current query; most
   of the time, it's ok to mutate.
*/

- _me {
    return self;
}

- all {
    var results = [IFArray new];
    var result;
    var c = 0;
    while (result = [self next]) {
        [results addObject:result];
        c++; // is a shit language
    }
    [self reset];
    [IFLog database:"Fetched " + c + " results"];
    return results;
}

- first {
    [self _execute];
    var result = [self next];
    [self _close];
    return result;
}

- one {
    [self _execute];
    var result = [self next];
    if (_readAhead) {
        [IFLog error:"Expected one result, got > 1"];
        /* yack here? */
    }
    return result;
}

/* TODO Should probably optimise this to store the value
   so that it doesn't fire off this query every time count()
   is called.
*/
- count {
    return [_oc countOfEntitiesMatchingFetchSpecification:[self fetchSpecification]];
}

- next {
    if (!_sth) {
        [self _execute];
    }
    if (![IFLog assert:(_sth && _fs) message:"Statement handle and fetch spec are present"]) { return }
    var rows = [self _readRowsForSingleResult];
    if (!rows || rows.length == 0) { return nil }
    //[IFLog debug:rows];
    var unpackedResults = [_fs unpackResultsIntoEntities:rows inObjectContext:_oc];
    if (![IFLog assert:([unpackedResults count] == 1) message:"Got one result back"]) {
        [IFLog debug:unpackedResults];
    }
    _fetchCount++;
    if (_fetchLimit > 0 && _fetchCount >= _fetchLimit) {
        /*IF::Log::debug("Reached fetch count, closing fetch"); */
        [self _close];
    }
    return [unpackedResults objectAtIndex:0];
}

/* this gets called once per next() because
   sometimes we need to read multiple rows to retrieve
   a single entity; for example, when prefetching on
   a relationship, or qualifying across a relationship
*/
- _readRowsForSingleResult {
    var rowBuffer = [];
    /* grab a row that we read ahead if there is one */
    if (_readAhead) {
        rowBuffer[rowBuffer.length] = _readAhead;
        _readAhead = nil;
    } else {
        [IFLog debug:"No readahead, so it's either the beginning or the end"];
    }
    /* our conditions for exiting the loop are:
       * we are finished fetching all rows
       * we fetch a row with a different PK value
       * there's an error
    */

    /* TODO refactor; this can all be done once on _execute() */
    var se = [_fs sqlExpression];
    var defaultTable = se._defaultTable;
    [IFLog assert:defaultTable message:"Using default table"];
    var defaultTableAlias = [se aliasForTable:defaultTable];
    [IFLog assert:defaultTableAlias message:"Using default table alias"];
    var ecd = [se entityClassDescriptionForTableWithName:defaultTable];
    [IFLog assert:ecd message:"Using ecd"];
    var pkColumnName = defaultTableAlias + "_" + [[ecd _primaryKey] asString].toUpperCase();
    var pkValue;
    if (rowBuffer.length > 0) {
        pkValue = [rowBuffer[0] objectForKey:pkColumnName];
        //[IFLog debug:"Using PK value " + pkValue + " from last fetch"];
    }
    var row;
    while (row = [self _readRow]) {
        if (!pkValue) {
            pkValue = [row objectForKey:pkColumnName];
        }
        var currentPkValue = [row objectForKey:pkColumnName];

        if (pkValue != currentPkValue) {
            /* on exit, if we read a row and it's not processed yet,
               put it into $self->{_readAhead} for processing
               next time
            */
            _readAhead = row;
            break;
        }

        /*IF::Log::debug("PK value is $currentPkValue for $pkColumnName"); */
        rowBuffer[rowBuffer.length] = row;
    }

    return rowBuffer;
}

- _readRow {
    if (_isComplete) { return nil }
    var row;
    if (!(row = [_sth nextResultAsDictionary])) {
       /* we're at the end of the fetch so close it out */
       [self _close];
       return nil;
    }
    var allKeys = [row allKeys];
    for (var i=0; i<[allKeys count]; i++) {
        var uk = k.toUpperCase();
        [row setObject:[row objectForKey:k] forKey:uk];
        if (!k.match(/^[A-Z0-9_]+$/)) {
            [row removeObjectForKey:k];
        }
    }
    return row;
}

- (void) setEntity:(id)ecn {
    _entity = ecn;
}

- (id) entity {
    return _entity;
}

@end
