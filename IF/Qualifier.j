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


/*=====================================
   Qualifier
   Abstracts SQL qualifiers
   into a tree-based system of
   related qualifiers
*/

@import "Object.j"
@import "Log.j"
@import "DB.j"
@import "Model.j"
//@import "Utility.j"
@import "Relationship/Derived.j"
@import "Relationship/Modelled.j"

var QUALIFIER_TYPES = {
    "AND": 1,
    "OR" : 2,
    "KEY": 3,
    "SQL": 4,
    "MATCH": 5,
};

var QUALIFIER_OPERATORS = [
    "=",
    '>=',
    '<=',
    '<>',
    '>',
    '<',
    '!=',
    'LIKE',
    'REGEXP',
    'IN',
    'NOT IN',
    'IS',
    'IS NOT',
];

var QUALIFIER_REGEX = "(" + QUALIFIER_OPERATORS.join("|") + ")";

@implementation IFQualifier : IFObject
{
    CPString type       @accessors;
    bool isNegated      @accessors;
    id entity @accessors;
}

- initWithType:(id)qualifierType {
    [self init];
	type = qualifierType;
    return self;
}

// helper constructors:
// these should clean up the consumers a tad

+ and:(IFArray)qs {
    return [IFAndQualifier newWithQualifiers:qs];
}

+ or:(IFArray)qs {
    return [IFOrQualifier newWithQualifiers:qs];
}

+ sql:(id)condition {
    return [IFSQLQualifier newWithCondition:condition];
}

// form is
// IF::Qualifier->match("attribute, attribute, ...", "terms")
// where, if the attribute list is empty, we'll use all text attributes
// in the entity.  "terms" must be present and can use boolean
// terms (in the expected MySQL format).
+ match:(id)attributes terms:(id)terms {
    return [IFMatchQualifier newWithAttributes:attributes andTerms:terms];
}

//--- instance methods ----

- (IFSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model {
	return [self sqlWithBindValuesForExpression:sqlExpression andModel:model andClause:"WHERE"];
}

- (IFSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model andClause:(id)clause {
    [self subclassResponsibility];
}

// This is a bit of a mess because it actually assumes that the
// derived source is >first< right now, as in
// "DerivedSource.foo = id" whereas it should allow the
// derived source to be anywhere in the key path.

- translateDerivedRelationshipQualifier:(id)relationship intoSQLExpression:(id)sqlExpression forModel:(id)model {
    // argh parsing
	var re = new RegExp("^\\\s*([\\\w\\\._-]+)\\\s*" + QUALIFIER_REGEX + "\\\s*(ANY|ALL|SOME)?(.*)$", "i");
    var yn = condition.match(re);
    if (!yn) { [IFLog error:"Failed to parse " + condition + " as legitimate derived qualifier"]; return }
    var sourceKeyPath    = yn[1];
    var operator         = yn[2];
    var subqueryOperator = yn[3];
    var targetKeyPath    = yn[4];

	var recd = [model entityClassDescriptionForEntityNamed:entity];
    var sourceGoo = [recd parseKeyPath:sourceKeyPath withSQLExpression:sqlExpression andModel:model];
	var rhs = targetKeyPath;

    if (expressionIsKeyPath(targetKeyPath)) {
        var targetGoo = [recd parseKeyPath:targetKeyPath withSQLExpression:sqlExpression andModel:model];
        var rtecd;
		if (rtecd = targetGoo.TARGET_ENTITY_CLASS_DESCRIPTION) {
			// create SQL for the qualifier on >that< entity
			var tableName = [rtecd _table];
			var columnName = [rtecd columnNameForAttributeName:targetGoo.TARGET_ATTRIBUTE];
			if ([sqlExpression hasSummaryAttribute:targetGoo.TARGET_ATTRIBUTE forTable:tableName]) {
				columnName = [sqlExpression aliasForSummaryAttribute:targetGoo.TARGET_ATTRIBUTE onTable:tableName];
			}
			var tableAlias = [sqlExpression aliasForTable:tableName];

			rhs = tableAlias + "." + columnName;
		}
	}

	var secd = sourceGoo.TARGET_ENTITY_CLASS_DESCRIPTION;

	var tableAlias = [sqlExpression aliasForTable:[relationship name]];
	var itn = [[[relationship fetchSpecification] entityClassDescription] _table];
	var columnName = [[[relationship fetchSpecification] entityClassDescription] columnNameForAttributeName:sourceGoo.TARGET_ATTRIBUTE];
	columnName = [[[relationship fetchSpecification] sqlExpression] aliasForColumn:columnName onTable:itn];
	if (!columnName) {
		if ([[[relationship fetchSpecification] sqlExpression] hasSummaryAttribute:sourceGoo.TARGET_ATTRIBUTE forTable: [[[relationship fetchSpecification] entityClassDescription] _table]]) {
            columnName = [[[relationship fetchSpecification] sqlExpression] aliasForSummaryAttribute:sourceGoo.TARGET_ATTRIBUTE onTable: [[[relationship fetchSpecification] entityClassDescription] _table]];
		} else {
			[IFLog debug:"Couldn't find alias for column " + sourceGoo.TARGET_ATTRIBUTE];
		}
	}
	var lhs = tableAlias + "." + columnName;
	return [IFSQLStatement newWithSQL:[lhs, operator, subqueryOperator, rhs].join(" ") andBindValues:bindValues];
}

- hasSubQuery {
	return ([self subQuery] ? true : false);
}

- subQuery {
    var bven = [bindValues objectEnumerator], bv;
	while (bv = [bven nextObject]) {
        if (bv.isa && [bv isKindOfClass:IFFetchSpecification]) {
            return bv;
        }
	}
	return nil;
}

@end


// qualifier subclasses

@implementation IFBooleanQualifier : IFQualifier
{
    id subqualifiers @accessors;
}

+ newWithType:(id)type qualifiers:(id)quals {
    var q = [[self alloc] initWithType:type];
    var qs = [IFArray arrayFromObject:quals];
    // don't allow these qualifiers without subqualifiers
    if (!qs || [qs count] == 0) { return nil };
    if ([qs count] == 1) { return [qs objectAtIndex:0]; }
    var validQualifiers = [IFArray new];
    for (var i=0; i < qs.length ; i++) {
        var cq = qs[i];
        if (!cq) { continue }
        [validQualifiers addObject:cq];
    }
    [q setSubqualifiers:validQualifiers];
    return q;
}

- (id) description {
    var d = "<IFQualifier [ " + entity + " ] - " + type + " " + [self subqualifiers] + ">";
    return d;
}

- setEntity:(id)e {
    var sqe = [subqualifiers objectEnumerator], sq;
    while (sq = [sqe nextObject]) {
        [sq setEntity:e];
    }
    entity = e;
}

- (IFSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model andClause:(id)clause {
    var subqualifierSQL = [IFArray new];
    var subqualifierBindValues = [IFArray new];
    var sqe = [subqualifiers objectEnumerator], sq;
    while (sq = [sqe nextObject]) {
        var subqualifierSQLStatement = [sq sqlWithBindValuesForExpression:sqlExpression andModel:model andClause:clause];
        [subqualifierSQL addObject:[subqualifierSQLStatement sql]];
        var bvs = [subqualifierSQLStatement bindValues];
        if (bvs && [bvs count] > 0) {
            [subqualifierBindValues addObjectsFromArray:bvs];
        }
    }
    if ([self isNegated]) {
        qualifierAsSQL = " NOT (" + qualifierAsSQL + ") ";
    }
    var qualifierAsSQL = "(" + [subqualifierSQL componentsJoinedByString:" " + type + " "] + ")";
    return [IFSQLStatement newWithSQL:qualifierAsSQL andBindValues:subqualifierBindValues];
}

@end

//-------------------------------------------------------------
@implementation IFAndQualifier : IFBooleanQualifier

+ (IFQualifier) newWithQualifiers:(id)qualifiers {
    return [self newWithType:"AND" qualifiers:qualifiers];
}

@end
//-------------------------------------------------------------

//-------------------------------------------------------------
@implementation IFOrQualifier : IFBooleanQualifier

+ newWithQualifiers:(id)qualifiers {
    return [self newWithType:"AND" qualifiers:qualifiers];
}

@end
//-------------------------------------------------------------


//-------------------------------------------------------------
@implementation IFSQLQualifier : IFQualifier
{
    IFArray bindValues @accessors;
    CPString condition @accessors;
}

+ newWithCondition:(id)condition {
    var q = [[self alloc] initWithType:"SQL"];
    [q setCondition:condition];
    return q;
}

- (IFSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model andClause:(id)clause {
	// short-circuit qualifiers that don't need to be translated.
	// TODO : rework the SQL in these to use the table aliases
    return [IFSQLStatement newWithSQL:condition andBindValues:bindValues];
}

- (id) description {
    var d = "<IFSQLQualifier [ " + entity + " ] - " + [self condition] + " >";
    return d;
}

@end
//-------------------------------------------------------------


//-------------------------------------------------------------
@implementation IFKeyValueQualifier : IFQualifier
{
    IFArray bindValues @accessors;
    CPString condition @accessors;
    bool requiresRepeatedJoin;
}

+ key:(id)condition bindValues:(id)bvs {
    var q = [[self alloc] initWithType:"KEY"];
    [q setCondition:condition];
    [q setBindValues:bvs];
    return q;
}

+ key:(id)condition, ... {
    var args = [IFArray new];
    for (var i=3; arguments[i] != nil; i++) {
        [args addObject:arguments[i]];
    }
    return [self key:condition bindValues:args];
}

- init {
    [super init]
	bindValues = [],
	requiresRepeatedJoin = false;
    condition = null;
    return self;
}

- (id) description {
    var d = "<IFKeyValueQualifier [ " + entity + " ] - " + [self condition] + " ( " + [self bindValues] + " ) >";
    return d;
}

- requiresRepeatedJoin {
    requiresRepeatedJoin = true;
    return self;
}

- (IFSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model andClause:(id)clause {
	// short-circuit qualifiers that don't need to be translated.
	// TODO : rework the SQL in these to use the table aliases
    //

	// There are three parts to a key-qualifier:
	// 1. key path
	// 2. operator
	// 3. values
    //

	var re = new RegExp("^\\\s*([\\\w\\\._-]+)\\\s*" + QUALIFIER_REGEX + "\\\s*(ANY|ALL|SOME)?(.*)$", "i");
    var yn = condition.match(re);
    if (!yn) {
        [CPException raise:"CPException" reason:"Qualifier condition is not well-formed: " + condition];
        return nil;
    }
    var keyPath = yn[1];
    var operator = yn[2];
    var subqueryOperator = yn[3];
    var value = yn[4];
    //[IFLog dump:[ keyPath, operator, subqueryOperator, value ]];

	var ecd = [model entityClassDescriptionForEntityNamed:entity];
	if (![IFLog assert:ecd message:"Entity class description exists for self.entity for self.condition"]) { return nil; }
	var oecd = ecd;  // original ecd
	var cecd = ecd;  // current ecd

	// Figure out the target ecd for the qualifier by looping through the keys in the path

	var bits = [keyPath componentsSeparatedByString:/\./];

	if ([bits count] == 0) { bits = [keyPath] }

	var qualifierKey;
    var deferredJoins = [IFArray new];

	for (var i=0; i < [bits count]; i++) {
		qualifierKey = [bits objectAtIndex:i];

		// if it's the last key in the path, bail now
        if (i >= ([bits count] - 1)) { break }

		// otherwise, look up the relationship
		var relationship = [cecd relationshipWithName:qualifierKey];

		// if there's no such relationship, it might be a derived data source
		// so check for that
        //
		if (!relationship) {
			relationship = [sqlExpression derivedDataSourceWithName:qualifierKey];
			// short circuit the rest of the loop if it's a derived
			// relationship because we don't need to add any
			// relationship traversal info to the sqlExpression
            //
			if (relationship) {
				return [self translateDerivedRelationshipQualifier:relationship intoSQLExpression:sqlExpression forModel:model];
			}
		}

		if (!relationship) {
			relationship = [sqlExpression dynamicRelationshipWithName:qualifierKey];
			//IF::Log::debug("Using dynamic relationship");
		}

		if (![IFLog assert:relationship message:"Relationship " + qualifierKey + " exists on entity " + [cecd name]]) {
			return [IFSQLStatement newWithSQL:"" andBindValues:[]];
		}
		var tecd = [relationship targetEntityClassDescription:model];

		if (![IFLog assert:tecd message:"Target entity class " + [relationship targetEntity] + " exists"]) {
            return [IFSQLStatement newWithSQL:"" andBindValues:[]];
	    }

        //
		// ([tecd isAggregateEntity]) {
		//  // We just bail on it if it's aggregate
	    //	// TODO see if there's a way to insert an aggregate qualifier into the key path
        //  //
		//	return [self _translateQualifierWithGoo:
		//			bits[i+1],
		//			relationship,
		//			tecd,
		//			model,
		//			sqlExpression,
		//			operator,
		//			value
		//		];
		//}
        //

		// add traversed relationships to the SQL expression
		if (requiresRepeatedJoin) {
		    [deferredJoins addObject:{ ecd: cecd, key: qualifierKey }];
		} else {
		    [sqlExpression addTraversedRelationship:qualifierKey onEntity:cecd];
        }

		// follow it
		cecd = tecd;
	}

	// create SQL for the qualifier on >that< entity
	var tableName = [cecd _table];

	var columnName = [cecd columnNameForAttributeName:qualifierKey];
	if ([sqlExpression hasSummaryAttribute:qualifierKey forTable:tableName]) {
		columnName = [sqlExpression aliasForSummaryAttribute:qualifierKey onTable:tableName];
	}

    // allow a column name to be specified directly:
    if (!columnName && [cecd hasColumnNamed:qualifierKey]) {
        columnName = qualifierKey;
    }

    var tn = tableName;

    // XXX! Kludge! XXX!
	if (requiresRepeatedJoin) {
	    tn = [sqlExpression addRepeatedTable:tn];
    }
	var tableAlias = [sqlExpression aliasForTable:tn];
	[IFLog assert:tableAlias message:"Alias for table tn is tableAlias"];

	var conditionInSQL;
	var bvs;

	if ([self hasSubQuery]) {
		var sq = value;
		var sqlWithBindValues = [[self subQuery] toSQLFromExpression];
        var sqre = new RegExp("\%\@");
		sq.replace(sqre, "(" + [sqlWithBindValues sql]  + ")");
		conditionInSQL = tableAlias + "." + columnName + " " + operator + " " +  subqueryOperator + " " +  subquery;
		bvs = [sqlWithBindValues bindValues];
	} else {
        //
		//var aggregateColumns = {
		//	uc([oecd aggregateKeyName]): 1,
		//	uc([oecd aggregateValueName]): 1,
		//	"creationDate": 1,
		//	"modificationDate": 1,
		//};
		//if ([oecd isAggregateEntity]
		//	&& !aggregateColumns[uc(columnName)]
		//	&& ![oecd _primaryKey]->hasKeyField(uc(columnName))) {
		//	conditionInSQL = "tableAlias + "[.oecd aggregateKeyName].
		//					" = %@ AND tableAlias + "[.oecd aggregateValueName].
		//					" operator value";
		//	bindValues = [columnName, @{self._bindValues}];
		//} else {
        //
		    //IF::Log::debug("MEOW $value");
		    // TODO... I am pretty sure this code is redundant now;
		    // the code above takes care of resolving the key paths now.
            //
			if (expressionIsKeyPath(value)) {
				//[IFLog debug:"key path"];
                var targetGoo = [ecd parseKeyPath:value withSQLExpression:sqlExpression andModel:model];
				var tecd = targetGoo.TARGET_ENTITY_CLASS_DESCRIPTION;
				var ta = targetGoo.TARGET_ATTRIBUTE;
				if (tecd) {
				    var tn = [ecd _table];

				    // XXX! Kludge! XXX!
                	if (requiresRepeatedJoin) {
                        // add that to the fetch representation
                        tn = [sqlExpression addRepeatedTable:tn];
                    }

					var targetTableAlias = [sqlExpression aliasForTable:tn];
					var targetColumnName = [sqlExpression aliasForColumn:ta onTable:[ecd _table]];

					value = targetTableAlias + "." + targetColumnName;
				}
			}
			conditionInSQL = tableAlias + "." + columnName + " " + operator + " " + value;
			bvs = bindValues;
		//}
        conditionInSQL = conditionInSQL.split("%@").join('?');
	}

    // hack to add a join to a repeated qualifier
    var dje = [deferredJoins objectEnumerator], dj;
	while (dj = [dje nextObject]) {
	    [IFLog debug:"Adding repeated join on " + [dj.ecd name] + " with key " + dj.key];
	    [sqlExpression addRepeatedTraversedRelationship:dj.key onEntity:dj.ecd];
	}

	return [IFSQLStatement newWithSQL:conditionInSQL andBindValues:bindValues];
}

@end


@implementation IFMatchQualifier : IFQualifier
{
    IFArray matchAttributes @accessors;
    CPString matchTerms  @accessors;
}

+ newWithAttributes:(id)attributes andTerms:(id)terms {
    var q = [[self alloc] initWithType:"MATCH"];
    var re = new RegExp(",\s*");
    [q setMatchAttributes:[attributes componentsSeparatedByString:re]];
    [q setMatchTerms:terms];
    return q;
}

- (IFSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model andClause:(id)clause {
	var ecd = [model entityClassDescriptionForEntityNamed:entity];
	if (![IFLog assert:ecd message:"Entity class description exists for self.entity"]) { return {}; }
	var oecd = ecd;  // original ecd
	var cecd = ecd;  // current ecd

    // figure out the attributes
    var attributes = matchAttributes ? [matchAttributes copy] : [IFArray new];

    if ([attributes count] == 0) {
        var aten = [[oecd allAttributes] objectEnumerator], attribute;
        while (attribute = [aten nextObject]) {
            if (!attribute.TYPE.match(/(CHAR|TEXT|BLOB)/i)) { continue; }
            [attributes addObject:attribute];
        }
    }

    var mappedAttributes = [IFArray new];

    // calculate attributes by walking the key paths... is this even valid?

    var aten = [attributes objectEnumerator], attributeName;
    while (attributeName = [aten nextObject]) {
        var targetGoo = [oecd parseKeyPath:attributeName withSQLExpression:sqlExpression andModel:model];

    	var tecd = targetGoo.TARGET_ENTITY_CLASS_DESCRIPTION;
    	if (tecd) {
			var tableName = [tecd _table];
			var columnName = [tecd columnNameForAttributeName:targetGoo.TARGET_ATTRIBUTE];
			var tableAlias = [sqlExpression aliasForTable:tableName];

            [mappedAttributes addObject:tableAlias + "." + columnName];
		}
    }

    [IFLog dump:"Matching on " + [mappedAttributes componentsJoinedByString:", "]];
    // TODO escape terms here.
    var terms = matchTerms.split(/\s+/);

    return [IFSQLStatement newWithSQL:"MATCH(" + [mappedAttributes componentsJoinedByString:", "] + ") AGAINST (? IN BOOLEAN MODE)"
            andBindValues:[terms componentsJoinedByString:" "]];
}

@end


var KP_RE = new RegExp('^[A-Za-z_\(\)]+[A-Za-z0-9_#\@\.\(\)\"]*$');
var KP_RE_PLUS = new RegExp('^[A-Za-z_\(\)]+[A-Za-z0-9_#\@]*[\(\.]+');

function expressionIsKeyPath(expression) {
	if ( expression.match(KP_RE) ) { return true }
	return expression.match(KP_RE_PLUS);
}
