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

/* Perhaps we need to rename this to QueryBuilder or something

   this should be subclassed to provide
   custom behaviour for different DBs
*/


@import "Object.j"
@import "DB.j"
@import "Qualifier.j"
@import "Relationship/Derived.j"
@import "Relationship/Modelled.j"

var UTIL = require("util");

@implementation IFSQLExpression : IFObject
{
}

- init {
    // FIXME make these instance properties
	var template = {
		_entityClassDescriptions: {},
		_tables: {},
		_tablesInFetch: {},
		_columns: {},
		_summaryAttributes: {},
		_aliasCounter: 0,
		_repeatedJoinCounts: {},
		_tableAliasMap: {},
		_qualifierBindValues: [],
		_derivedBindValues: [],
		_qualifier: "",
		_sortOrderings: [],
		_groupBy: [],
		_fetchLimit: null,
		_startIndex: 0,
		_traversedRelationships: {},
        _traversedRelationshipCounts: {},
		_prefetchedRelationships: {},
		_dynamicRelationships: {},
		_defaultTable: '',
		_doNotFetch: {},
		_onlyFetch: {},
		_columnAndSummaryAliases: {},
	};

    for (var key in template) {
		self[key] = template[key];
	}
    return self;
}

- tablesAsSQL {
	var tables = [];
    var sortedTables = UTIL.sort(UTIL.keys(self._tables));

	for (var i=0; i < sortedTables.length; i++) {
        var tableName = sortedTables[i];
//		if (tableName == self._defaultTable && UTIL.keys(self._prefetchedRelationshipClause).length > 0) {
//            continue;
//        }
		var table = self._tables[tableName];
		if ([self isDerivedTable:table]) {
			tables[tables.length] = "(" + [table['EXPANSION'] sql] + ") " + [self aliasForTable:tableName];
		} else {
//			if (!self._prefetchedRelationshipClause[tableName]) {
			    var tn = table['NAME']
			    /* XXX Kludge! XXX */
        		tn = tn.replace(/_XXX_[0-9]+$/g, "");
        		/* XXX End kludge! XXX */
				tables[tables.length] = tn + " " + [self aliasForTable:tableName];
//			} else {
//				tables[tables.length] = self._prefetchedRelationshipClause[tableName];
//			}
		}
	}
	return tables.join(", ");
}


- addTable:(id)table {
	if ([self tableWithName:table]) { return }
	[self addRelatedTable:table];
	if (!self._defaultTable) {
		self._defaultTable = table;
	}
}

/* This is the same as the previous method but does
   not set the table as a default.  This is key
   because sometimes you want to dangle a table
   off to the side for a purpose, but not have it
   part of the fetch, or indeed part of the model
   at all
*/
- addRelatedTable:(id)table {
	if ([self tableWithName:table]) { return }

	self._tables[table] = {
		NAME: table,
		ALIAS: self._aliasCounter,
	};
	self._tableAliasMap[self._aliasCounter] = table;
	self._aliasCounter++;
}

- addRepeatedTable:(id)tn {
    var c = self._repeatedJoinCounts[tn] + 1 || 1;
    self._repeatedJoinCounts[tn] = c;

    /* Create a fake table name */
    tn += "_XXX_" + self._repeatedJoinCounts[tn];

    /* add that to the fetch representation */
    [self addRelatedTable:tn];

    /* This hack is necessary to inform the qualifier that its table name has changed */
    return tn;
}


/* when adding a derived source, you need to name it, although the name
   will never show in the resulting SQL; it's for internal use only.
*/
- addDerivedDataSourceWithDefinition:(id)fetchSpecification andName:(id)name {
	if ([self tableWithName:name]) { return }

	self._tables[name] = {
		NAME: name,
		ALIAS: self._aliasCounter,
		DEFINITION: fetchSpecification,
		EXPANSION: [fetchSpecification toSQLFromExpression],
	};

	self._tableAliasMap[self._aliasCounter] = name;
	if (!self._defaultTable) {
		self._defaultTable = name;
	}

	/* drop the bind values in.  These need to appear BEFORE the bind values
	   that are bound into the WHERE clause.
    */
	[self appendDerivedBindValues:[self._tables[name]['EXPANSION'] bindValues]];
	self._aliasCounter++;
}

- derivedDataSourceWithName:(id)name {
	var t = [self tableWithName:name];
	if (t && [self isDerivedTable:t]) {
		return [IFRelationshipDerived newFromFetchSpecification:t.DEFINITION withName:name];
	}
	return nil;
}

- tableWithName:(id)name {
	return self._tables[name];
}

- aliasForTable:(id)name {
	var table = [self tableWithName:name];
	/* XXX hack - failover to the table alias
	   that is there because it's a repeated join.
    */
	if (!table) {
	    var jc = self._repeatedJoinCounts[name];
	    if (jc) {
	        table = [self tableWithName:name + "_XXX_" + jc];
	    }
	}
	/* End XXX Hack */
	if (!table) { return }
	if ([self isDerivedTable:table]) {
		return "D" + table.ALIAS;
	}
	return "T" + table.ALIAS;
}



- isDerivedTable:(id)table {
	if (table['EXPANSION']) {
		return true;
	}
	return false;
}

- addTableToFetch:(id)tableName {
	self._tablesInFetch[tableName] = 1;
}

- addRepeatedTraversedRelationship:(id)relationshipName onEntity:(id)ecd {
    [self addTraversedRelationship:relationshipName onEntity:ecd :true];
}

/* TODO refactor this... it needs to call something called
   "qualifierForTraversedRelationshipOnEntity" to generate
   the SQL
*/

- (void) addTraversedRelationship:(id)relationshipName onEntity:(id)entityClassDescription {
    [self addTraversedRelationship:relationshipName onEntity:entityClassDescription :false];
}

- (void) addTraversedRelationship:(id)relationshipName onEntity:(id)entityClassDescription :(id)shouldTraverseToRepeatedTable {
	if (!shouldTraverseToRepeatedTable && self._traversedRelationships[relationshipName]) {
		return;
	}
	var relationship = [entityClassDescription relationshipWithName:relationshipName]
                    || [self dynamicRelationshipWithName:relationshipName];
	if (!relationship) { return }

    if (shouldTraverseToRepeatedTable) {
        [IFLog debug:"Traversing to repeated table via " + relationshipName + " on " + [entityClassDescription name]]
    }
    // FIXME don't use the default model here.
	var model = [IFModel defaultModel];
	var targetEntityName = [relationship targetEntity];
	var targetEntity = [relationship targetEntityClassDescription:model];
	var sourceTable = [entityClassDescription _table];
	var sourceTableAlias = [self aliasForTable:sourceTable];
	var targetTable = [targetEntity _table];

	/* XXX HAck! */
	if (shouldTraverseToRepeatedTable) {
	    self._traversedRelationshipCounts[relationshipName]++;
	    var newTableName = targetTable + "_XXX_" + self._repeatedJoinCounts[targetTable];
	    if ([IFLog assert:[self tableWithName:newTableName] message:"newTableName is already registered"]) {
	        targetTable = newTableName;
	    }
	}
	/* End XXX Hack! */

	if (![self tableWithName:targetTable]) {
		[self addTable:targetTable];
		self._entityClassDescriptions[targetEntityName] = targetEntity;
	}
	var targetTableAlias = [self aliasForTable:targetTable];
	var sourceAttribute = [relationship sourceAttribute];
	var targetAttribute = [relationship targetAttribute];
	var qualifiers = [];
	if ([relationship type] == "FLATTENED_TO_MANY") {
		var joinTable = [relationship joinTable];

		/* XXX hack! */
		if (shouldTraverseToRepeatedTable) {
		    joinTable = [self addRepeatedTable:joinTable];
		}
		if (![self tableWithName:joinTable]) {
			[self addTable:joinTable];
		}
		var joinTableAlias = [self aliasForTable:joinTable];
		qualifiers[qualifiers.length] = sourceTableAlias + "." + sourceAttribute + " = " + joinTableAlias + "." + [relationship joinTargetAttribute];
		qualifiers[qualifiers.length] = joinTableAlias + "." + [relationship joinSourceAttribute] + " = " + targetTableAlias + "." + targetAttribute;

        /* Hmmmm, why are join qualifiers added in here? */
        if ([relationship joinQualifiers]) {
            for (var k in [relationship joinQualifiers]) {
                qualifiers[qualifiers.length] = joinTableAlias + "." + k + " = ?";
                // Add the value in as a bind value; this is new behaviour for js
                self._qualifierBindValues[self._qualifierBindValues] = [relationship joinQualifiers][k];
            }
        }
	} else {
		qualifiers[qualifiers.length] = sourceTableAlias + "." + sourceAttribute + " = " + targetTableAlias + "." + targetAttribute;
	}
	/* there is a potential "loop" here, not sure how to trap it (where
	   this is called by translateCondition...() which in turn calls translateCondition...())
    */
	if ([relationship qualifier]) {
		var q = [relationship qualifier];
		[q setEntity:targetEntityName];
		var c = [[relationship qualifier] translateConditionIntoSQLExpression:self forModel:model];

		if ([[c bindValues] count] > 0) {
			/* tricky case, where there's a bind value in the qualifier that's
			   being injected, but there's no way to pass that bind value out
			   and insert it into the ordering
			   For now we are going to >assume< we can quote values, and insert them
			   directly in place of the '?'s.
*/
			var s = [c sql];
			for (var i=0; i < [[c bindValues] count]; i++) {
                b = [[c bindValues] objectAtIndex:i];
				var qb = [IFDB quote:b];
				s.replace(/\?/, qb);
			}
			qualifiers[qualifiers.length] = s;
		} else {
			qualifiers[qualifiers.length] = [c sql];
		}
	}

	/* XXX HACK! */
	if (shouldTraverseToRepeatedTable) {
	    relationshipName += "_XXX_" + self._traversedRelationshipCounts[relationshipName];
	}
	self._traversedRelationships[relationshipName] = qualifiers.join(" AND ");
}


- addPrefetchedRelationship:(id)relationshipName onEntity:(id)entityClassDescription {
	[self addEntityClassDescription:entityClassDescription];
    // FIXME don't use the default model
	var model = [IFModel defaultModel];
	var relationship = [entityClassDescription relationshipWithName:relationshipName]
                    || [self dynamicRelationshipWithName:relationshipName];
	if (!relationship) { return }

	var targetEntityClass = [relationship targetEntityClassDescription:model];
	[self addEntityClassDescription:targetEntityClass];
	[self addTraversedRelationship:relationshipName onEntity:entityClassDescription];
    var ten = [relationship targetEntity];
	self._prefetchedRelationships[ten] = relationshipName;
	[self addTableToFetch:[targetEntityClass _table]];
}

- relationshipNameForEntityType:(id)entityType {
	var r = self._prefetchedRelationships[entityType];
	if (r) { return r }

	for (var drn in self._dynamicRelationships) {
        var dr = self._dynamicRelationships[drn];
		if (![[dr targetEntityClassDescription] name] == entityType) { continue };
		return [dr name];
	}
	return nil;
}

- dynamicRelationshipWithName:(id)relationshipName {
	return self._dynamicRelationships[relationshipName];
}

- addDynamicRelationship:(id)dr {
    if (![IFLog assert:dr message:"Adding dynamic relationship"]) { return }
	var defaultTable = self._defaultTable;
	if (defaultTable) {
		[dr setEntityClassDescription:[self entityClassDescriptionForTableNamed:defaultTable]];
	}
    var dn = [dr name];
	self._dynamicRelationships[dn] = dr;
}

- dynamicRelationshipNames {
	return UTIL.keys(self._dynamicRelationships);
}

- removeTableWithName:(id)name {
	var aliasForTable = [self aliasForTable:name];
	delete self._tables[name];
	delete self._tableAliasMap[aliasForTable];
	delete self._tablesInFetch[name];
}

- tables {
    return self._tables;
}

- columns {
	return self._columns;
}

- addColumn:(id)column forTable:(id)table {
	var tableEntry = [self tableWithName:table];
	if (!tableEntry) { return }
	[self addColumn:column forTable:table withAlias:[self aliasForTable:table] + "_"  + column];
}

- addColumn:(id)column forTable:(id)table withAlias:(id)alias {
    if (!self._columns[table]) {
        self._columns[table] = {};
    }
	self._columns[table][column] = {
		NAME: column,
		ALIAS: alias,
		TABLE: table,
	};
	self._columnAndSummaryAliases[alias.toUpperCase()] = self._columns[table][column];
}

- removeColumn:(id)column forTable:(id)table {
	if (![self tableWithName:table]) { return }
	delete self._columns[table][column];
}

- addSummaryAttribute:(id)summary forTable:(id)table {
	var tableEntry = [self tableWithName:table];
	if (!tableEntry) { return }
	[self addSummaryAttribute:summary forTable:table withAlias:[self aliasForTable:table] + "_" + [summary n]];
}

- addSummaryAttribute:(id)summary forTable:(id)table withAlias:(id)alias {
    var sn = [summary n];
    self._summaryAttributes[table] = self._summaryAttributes[table] || {};
	self._summaryAttributes[table][sn] = {
		NAME: sn,
		SUMMARY: summary,
		ALIAS: alias,
		TABLE: table,
	};
	self._columnAndSummaryAliases[alias.toUpperCase()] = self._summaryAttributes[table][sn];
}


- hasSummaryAttribute:(id)summaryName forTable:(id)tableName {
	return Boolean(self._summaryAttributes[tableName] && self._summaryAttributes[tableName][summaryName]);
}

- aliasForSummaryAttribute:(id)summaryName onTable:(id)tableName {
    self._summaryAttributes[tableName] = self._summaryAttributes[tableName] || {};
    if (!self._summaryAttributes[tableName][summaryName]) {
        return nil;
    }
	return self._summaryAttributes[tableName][summaryName]['ALIAS'];
}

- hasColumn:(id)column forTable:(id)tableName {
	return Boolean(self._columns[tableName][column]);
}

- aliasForColumn:(id)column onTable:(id)tableName {
    self._columns[tableName] = self._columns[tableName] || {};
    if (!self._columns[tableName][column]) {
        return nil;
    }
    return self._columns[tableName][column]['ALIAS'];
}

- columnsAsSQL {
	var columns = [];
    // FIXME: sort these first
	for (var tableName in self._tablesInFetch) {
		var table = self._columns[tableName];
		var tableAlias = [self aliasForTable:tableName];
        // FIXME: sort these first
		for (var column in table) {
			if (![self shouldFetchColumn:column forTable:tableName]) { continue }
			columns[columns.length] = tableAlias + "." + table[column]['NAME'] + " AS " + table[column]['ALIAS'];
		}
		table = self._summaryAttributes[tableName];
        // FIXME: sort these first
		for (var summaryName in table) {
			if (![self shouldFetchSummaryAttribute:summaryName forTable:tableName]) { continue }
			columns[columns.length] = [table[summaryName]['SUMMARY'] translateSummaryIntoSQLExpression:self] + " AS " + table[summaryName]['ALIAS'];
		}
	}
	return columns.join(", ");
}

- shouldFetchColumn:(id)column forTable:(id)table {
    // FIXME clean up this auto-vivification fallout shite
    var onlyFetchTable = self._onlyFetch[table] || { columns:{}, summaryAttributes:{} };
    var doNotFetchTable = self._doNotFetch[table] || { columns:{}, summaryAttributes:{} };
	if (Boolean(onlyFetchTable && onlyFetchTable['columns'][column])) return true;
	if (onlyFetchTable && _p_keys(onlyFetchTable['columns']).length > 0) return false;
	if (!Boolean(doNotFetchTable && doNotFetchTable['columns'][column])) return true;
	return false;
}

- shouldFetchSummaryAttribute:(id)summaryAttribute forTable:(id)table {
    // FIXME clean up this auto-vivification fallout shite
    var onlyFetchTable = self._onlyFetch[table] || { columns:{}, summaryAttributes:{} };
    var doNotFetchTable = self._doNotFetch[table] || { columns:{}, summaryAttributes:{} };
	if (Boolean(onlyFetchTable && onlyFetchTable['summaryAttributes'][summaryAttribute])) return true;
	if (onlyFetchTable && _p_keys(onlyFetchTable['summaryAttributes']).length > 0) return false;
	if (!Boolean(doNotFetchTable && doNotFetchTable['summaryAttributes'][summaryAttribute])) return true;
	return false;
}

- doNotFetchColumn:(id)column forTable:(id)table {
    self._doNotFetch[table] = self._doNotFetch[table] || { columns: {}, summaryAttributes: {} };
	self._doNotFetch[table]['columns'][column] = true;
}

- doNotFetchSummaryAttribute:(id)summaryAttribute forTable:(id)table {
    self._doNotFetch[table] = self._doNotFetch[table] || { columns: {}, summaryAttributes: {} };
	self._doNotFetch[table]['summaryAttributes'][summaryAttribute] = true;
}

- onlyFetchColumn:(id)column forTable:(id)table {
    self._onlyFetch[table] = self._onlyFetch[table] || { columns: {}, summaryAttributes: {} };
	self._onlyFetch[table]['columns'][column] = true;
}

- onlyFetchSummaryAttribute:(id)summaryAttribute forTable:(id)table {
    self._onlyFetch[table] = self._onlyFetch[table] || { columns: {}, summaryAttributes: {} };
	self._onlyFetch[table]['summaryAttributes'][summaryAttribute] = true;
}


- bindValues {
	return self._derivedBindValues.concat(self._qualifierBindValues);
}

- setQualifierBindValues:(id)qbvs {
	self._qualifierBindValues = qbvs;
}

- appendDerivedBindValues:(id)values {
	self._derivedBindValues = self._derivedBindValues || [];
    [self._derivedBindValues addObjectsFromArray:values];
}

- qualifier {
	return self._qualifier;
}

- setQualifier:(id)q {
	self._qualifier = q;
}

- summaryQualifier {
	return self._summaryQualifier;
}

- setSummaryQualifier:(id)sq {
	self._summaryQualifier = sq;
}

- hasSummaryQualifier {
	return Boolean(self._summaryQualifier);
}

- distinct {
	return self.distinct;
}

- setDistinct:(id)value {
	self.distinct = value;
}

/* TODO: Implement default sort orderings? */
- sortOrderings {
	return self._sortOrderings;
}

- setSortOrderings:(id)sos {
	self._sortOrderings = sos;
}

- groupBy {
	return self._groupBy;
}

- setGroupBy:(id)gb {
	self._groupBy = gb;
}


/* TODO: implement this so it can walk relationships */
- sortOrderingsAsSQL {
	var orderColumns = [];
	var decd = [self entityClassDescriptionForTableWithName:self._defaultTable];
	if ([self shouldFetchRandomly]) {
		orderColumns[orderColumns.length] = "RAND() ASC";
	}
    for (var i=0; i < self._sortOrderings.length; i++) {
        var o = self._sortOrderings[i];
        var bits = [o componentsSeparatedByString:/[ ]+/];
        var direction;
        var orderTerm;
        var att = o;
        // ignore anything past the 2nd thing
        if ([bits count] > 1) {
            att = [bits objectAtIndex:0];
            direction = [bits objectAtIndex:1];
        }
        var orderGoo = [decd parseKeyPath:att withSQLExpression:self andModel:nil];
        if (orderGoo) {
            var tecd = orderGoo['TARGET_ENTITY_CLASS_DESCRIPTION'];
            var tableName = [tecd _table];
            var tableAlias = [self aliasForTable:tableName];
            var columnName = [tecd columnNameForAttributeName:orderGoo['TARGET_ATTRIBUTE']];
            if (!columnName) {
                orderTerm = [self aliasForSummaryAttribute:orderGoo['TARGET_ATTRIBUTE'] onTable:tableName];
            } else {
                orderTerm = tableAlias + "." + columnName;
            }
        } else {
            [IFLog error:"Couldn't figure out what " + o + " means for ordering"];
        }
        if (orderTerm) {
            if (direction) { orderTerm = orderTerm + " " + direction }
            orderColumns[orderColumns.length] = orderTerm;
        }
    }
    return [orderColumns componentsJoinedByString:", "];
    /*
	var defaultTableAlias = [self aliasForTable:self._defaultTable];
	var defaultEntityClass = [self entityClassDescriptionForTableWithName:self._defaultTable];
	for (var i=0; i < self._sortOrderings.length; i++) {
        var ordering = self._sortOrderings[i];
		var columnName = ordering;
		var tableAlias;
		var orderBy;
		if (defaultEntityClass) {
			var (attributeName, direction) = columnName.split(/[ ]+/);
			if (attributeName =~ /\ + /) {
				var (relationshipName, attributeName) = split(/\ + /, attributeName, 2);
				if (self._traversedRelationships[relationshipName}) {
					var relationship = [defaultEntityClass relationshipWithName:relationshipName] || self->dynamicRelationshipWithName(relationshipName);
					if (relationship) {
						var targetEntityClassDescription = self._entityClassDescriptions[relationship.TARGET_ENTITY};
						if (targetEntityClassDescription) {
							tableAlias = [self aliasForTable:targetEntityClassDescription->_table()];
							columnName = [targetEntityClassDescription columnNameForAttributeName:attributeName];
							orderBy = "tableAlias + columnName";
						}
					}
				}
			} else {
				tableAlias = defaultTableAlias;
				if (self._summaryAttributes[self._defaultTable}[attributeName}) {
					columnName = self._summaryAttributes[self._defaultTable}[attributeName}[ALIAS};
					orderBy = columnName;
				} else {
					var columnNameForAttributeName = [defaultEntityClass columnNameForAttributeName:attributeName];
					columnName = columnNameForAttributeName || attributeName;
					orderBy = "tableAlias + columnName";
				}
			}
			if (direction) {
				orderBy .= " direction";
			}
		}
		push (@orderColumns, orderBy);
	}
	return join(", ", @orderColumns);
    */
}

/* This is also a rehash of the same code that's used in Qualifier to generate
   SQL... and also in IF::SummaryAttribute to generate its SQL too.  We can almost
   certainly rework it to share the same parsing code.
*/

- groupByAsSQL {
	var groupColumns = [];
	var decd = [self entityClassDescriptionForTableWithName:self._defaultTable];
    for (var i=0; i < self._groupBy.length; i++) {
        var g = self._groupBy[i];
        var groupGoo = [decd parseKeyPath:g withSQLExpression:self andModel:nil];
        if (groupGoo) {
            var tableName = [groupGoo['TARGET_ENTITY_CLASS_DESCRIPTION'] _table];
            var tableAlias = [self aliasForTable:tableName];
            var columnName = [self aliasForColumn:groupGoo['TARGET_ATTRIBUTE'] onTable:tableName];
            if (!columnName) {
                groupColumns[groupColumns.length] = [self aliasForSummaryAttribute:groupGoo['TARGET_ATTRIBUTE'] onTable:tableName];
            } else {
                groupColumns[groupColumns.length] = tableAlias + "." + columnName;
            }
        } else {
            [IFLog error:"Couldn't figure out what " + o + " means for ordering"];
        }
    }
    return [groupColumns componentsJoinedByString:", "];
    /*
	var groupColumns = [];
	var defaultTableAlias = [self aliasForTable:self._defaultTable];
	var defaultEntityClass = [self entityClassDescriptionForTableWithName:self._defaultTable];
	//IF::Log::debug("doing groupings for table $self[_defaultTable}...");
	foreach var grouping (@{self._groupBy}) {
		//IF::Log::debug("Checking for grouping $grouping");
		var tableAlias;
		var columnName;
		var groupBy;
		if (defaultEntityClass) {
			var attributeName = grouping;
			if (attributeName =~ /\ + /) {
				var (relationshipName, attributeName) = split(/\ + /, attributeName, 2);
				if (self._traversedRelationships[relationshipName} || [self dynamicRelationshipWithName:relationshipName]) {
					var relationship = [defaultEntityClass relationshipWithName:relationshipName]
										|| [self dynamicRelationshipWithName:relationshipName];
					if (relationship) {
						var targetEntityClassDescription = [relationship targetEntityClassDescription]
															|| self._entityClassDescriptions[relationship.TARGET_ENTITY};
						if (IFLog.assert(targetEntityClassDescription, "Located target entity class description for relationshipName")) {
							// This is crappy.  All of this needs to be refactored.
							unless (self._traversedRelationships[relationshipName}) {
								[self addTraversedRelationshipOnEntity:defaultEntityClass](relationshipName, defaultEntityClass);
							}
							tableAlias = [self aliasForTable:targetEntityClassDescription->_table()];
							columnName = [targetEntityClassDescription columnNameForAttributeName:attributeName];
							if (IFLog.assert(tableAlias && columnName, "We have a target table and column")) {
								groupBy = "tableAlias + columnName";
							}
						}
					} else {
						IFLog.error("Didn't find relationship relationshipName");
					}
				} else {
					// maybe it's an explicit table name or table alias:
					//  IF::Log::debug("Checking for table or alias name for $relationshipName");
					var tableName = [self aliasForTable:relationshipName] || relationshipName;
					var columnName = [self aliasForColumnOnTable:tableName](attributeName, tableName) || attributeName;
					if (tableName && columnName) {
						groupBy = tableName + "." + columnName;
					}
					//IF::Log::debug("....... grouping by $groupBy");
				}
			} else {
				//IF::Log::debug("Grouping by a straight attribute");
				tableAlias = defaultTableAlias;
				// check for summary attributes with this name
				if (self._summaryAttributes[self._defaultTable}[attributeName}) {
					columnName = self._summaryAttributes[self._defaultTable}[attributeName}[ALIAS};
					groupBy = columnName;
				} else {
					var columnNameForAttributeName = [defaultEntityClass columnNameForAttributeName:attributeName];
					groupBy = "tableAlias + columnNameForAttributeName";
				}
			}
		}
		push (@groupColumns, groupBy);
	}
	return join(", ", @groupColumns);
    */
}

- fetchLimit {
	return self._fetchLimit;
}

- setFetchLimit:(id)v {
	self._fetchLimit = v;
}

- startIndex {
	return self._startIndex;
}

- setStartIndex:(id)si {
	self._startIndex = si;
}

- shouldFetchRandomly {
	return self.shouldFetchRandomly;
}

- setShouldFetchRandomly:(id)value {
	self.shouldFetchRandomly = value;
}

- inflateAsInstancesOfEntityNamed {
	return self.inflateAsInstancesOfEntityNamed;
}

- setInflateAsInstancesOfEntityNamed:(id)value {
	self.inflateAsInstancesOfEntityNamed = value;
}


- selectStatement {
	var sql = "SELECT ";
	if ([self distinct]) {
		sql += "DISTINCT ";
	}
	sql += [self columnsAsSQL];
	sql += " FROM ";
	sql += [self tablesAsSQL];
	sql += [self whereClause];
	if ([self groupBy].length) {
		sql += " GROUP BY ";
		sql += [self groupByAsSQL];

		if ([self hasSummaryQualifier]) {
			sql += [self havingClause];
		}
	}
	if (([self sortOrderings] && [self sortOrderings].length > 0) || [self shouldFetchRandomly]) {
		sql += " ORDER BY ";
		sql += [self sortOrderingsAsSQL];
	}
	if ([self fetchLimit]) {
		sql += " LIMIT " + [self startIndex] + ", " + [self fetchLimit];
	}
	return sql;
}

- selectCountStatement {
	var sql;
	/* TODO NBNBNB This will not work if the table aliasing is changed! */
	var rootEntityClassDescription = [self entityClassDescriptionForTableWithName:[self tableNameForAlias:"0"]];

	if (rootEntityClassDescription) {
		var primaryKey = [rootEntityClassDescription _primaryKey];
		sql = "SELECT COUNT(DISTINCT T0." + primaryKey + ") AS COUNT FROM ";
	} else {
		sql = "SELECT COUNT(*) AS COUNT FROM ";
	}
	sql += [self tablesAsSQL];
	sql += [self whereClause];
	if ([self groupBy].length) {
		sql += " GROUP BY ";
		sql += [self groupByAsSQL];

		if ([self hasSummaryQualifier]) {
			sql += [self havingClause];
		}
	}
	return sql;
}

- whereClause {
	var sql = [self qualifier];
	var traversedRelationshipQualifiers = UTIL.values(self._traversedRelationships);
	if (traversedRelationshipQualifiers.length > 0) {
		if (sql != "") {
			sql += " AND ";
		}
		sql += traversedRelationshipQualifiers.join(" AND ");
	}
	if (sql != "") {
		return " WHERE "+ sql;
	}
	return "";
}

- havingClause {
	var sql = [self summaryQualifier];
	if (sql != "") {
		return " HAVING " + sql;
	}
	return "";
}


/* Convenience methods: */

- addTableAndColumnsForEntityClassDescription:(id)entityClassDescription {
	var table = [entityClassDescription _table];
    if (!table) { return }
	[self addTable:table];
    var atts = [entityClassDescription attributes];
    // var atten = [atts objectEnumerator], att;
    //while (att = [atten nextObject]) {
    for (k in atts) {
        var att = atts[k];
		[self addColumn:att['COLUMN_NAME'] forTable:table];
	}
}

- addEntityClassDescription:(id)entityClassDescription {
	[self addTableAndColumnsForEntityClassDescription:entityClassDescription];
    var en = [entityClassDescription name];
	self._entityClassDescriptions[en] = entityClassDescription;
	/* set the reverse-mapping: */
	var tableName = [entityClassDescription _table];
	var table = [self tableWithName:tableName];
	if (!table) { return }
	table.ENTITY_CLASS = entityClassDescription;
}

/* This is used for subqueries only: */
- addEntityClassDescription:(id)ecd withColumns:(id)columns {
	var table = [ecd _table];
	if (!table) { return }
	[self addTable:table];
	for (var i=0; i< columns.length; i++) {
		[self addColumn:columns[i] forTable:table];
	}
}

- entityClassDescriptionForTableWithName:(id)tableName {
	var table = [self tableWithName:tableName];
	if (!table) { return }
	return table.ENTITY_CLASS;
}

- tableNameForAlias:(id)alias {
	return self._tableAliasMap[alias];
}


/* perhaps this should be outside this class?
   TODO: allow table alias format to be set rather than
   hardcoded as t*
*/

- dictionaryOfEntitiesFromRawRow:(id)row {
	var tables = {};
	var entities = {};
	var objectContext = [IFObjectContext new];
    var keys = [row allKeys];
	for (var ki = 0; ki < [keys count]; ki++) {
        var key = [keys objectAtIndex:ki];
        var r;
        var r = key.match(/^T([0-9]+)_([A-Za-z0-9_]+)$/);
        if (!r) { [IFLog error:"Didn't match regexp for key " + key]; continue;  }
		var tableAlias = r[1];
		var columnName = r[2];
		var tableName = [self tableNameForAlias:tableAlias];
        tables[tableName] = tables[tableName] || [IFDictionary new];
		[tables[tableName] setObject:[row objectForKey:key] forKey:columnName];
	}
    //[IFLog dump:tables];
	for (var tableName in tables) {
		var ecd = [self entityClassDescriptionForTableWithName:tableName];
		if (ecd) {
			var entityName = nil;
            if (tableName == self._defaultTable) {
                entityName = [self inflateAsInstancesOfEntityNamed];
            }
            entityName = entityName || [ecd name];
            var newe = [objectContext entity:entityName fromRawHash:tables[tableName]];
            entities[entityName] = newe;
		} else {
			entities._RELATIONSHIP_HINTS = tables[tableName];
		}
	}
	return entities;
}

- dictionaryFromRawRow:(id)row {
	var dictionary = [IFDictionary new];
    var allKeys = [row allKeys];
	for (var i=0; i < [allKeys count]; i++) {
        var key = [allKeys objectAtIndex:i];
		var mappedKey = key;
		var alias = self._columnAndSummaryAliases[key.toUpperCase()];
		if (alias) {
			if (alias.SUMMARY) {
				mappedKey = alias.NAME;
			} else {
				var ecd = [self entityClassDescriptionForTableWithName:alias.TABLE];
				if (ecd) {
					mappedKey = [ecd attributeNameForColumnName:alias.NAME];
				}
			}
		}
        [IFLog debug:"setting " + mappedKey + " to " + [row objectForKey:key]];
		[dictionary setObject:[row objectForKey:key] forKey:mappedKey];
	}
	return dictionary;
}

@end
