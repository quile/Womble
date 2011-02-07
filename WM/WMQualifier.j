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


/*=====================================
   Qualifier
   Abstracts SQL qualifiers
   into a tree-based system of
   related qualifiers
*/

@import "WMObject.j"
@import "WMLog.j"
@import "WMDB.j"
@import "WMModel.j"
@import "WMUtility.j"
@import "Relationship/WMRelationshipDerived.j"
@import "Relationship/WMRelationshipModelled.j"

var QUALWMIER_TYPES = {
    "AND": 1,
    "OR" : 2,
    "KEY": 3,
    "SQL": 4,
    "MATCH": 5,
};

var QUALWMIER_OPERATORS = [
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

var QUALWMIER_REGEX = "(" + QUALWMIER_OPERATORS.join("|") + ")";

@implementation WMQualifier : WMObject
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

+ and:(WMArray)qs {
    return [WMAndQualifier newWithQualifiers:qs];
}

+ or:(WMArray)qs {
    return [WMOrQualifier newWithQualifiers:qs];
}

+ sql:(id)condition {
    return [WMSQLQualifier newWithCondition:condition];
}

// form is
// WM::Qualifier->match("attribute, attribute, ...", "terms")
// where, if the attribute list is empty, we'll use all text attributes
// in the entity.  "terms" must be present and can use boolean
// terms (in the expected MySQL format).
+ match:(id)attributes terms:(id)terms {
    return [WMMatchQualifier newWithAttributes:attributes andTerms:terms];
}

//--- instance methods ----

- (WMSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model {
    return [self sqlWithBindValuesForExpression:sqlExpression andModel:model andClause:"WHERE"];
}

- (WMSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model andClause:(id)clause {
    [self subclassResponsibility];
}

// This is a bit of a mess because it actually assumes that the
// derived source is >first< right now, as in
// "DerivedSource.foo = id" whereas it should allow the
// derived source to be anywhere in the key path.

- translateDerivedRelationshipQualifier:(id)relationship intoSQLExpression:(id)sqlExpression forModel:(id)model {
    // argh parsing
    var re = new RegExp("^\\\s*([\\\w\\\._-]+)\\\s*" + QUALWMIER_REGEX + "\\\s*(ANY|ALL|SOME)?(.*)$", "i");
    var yn = condition.match(re);
    if (!yn) { [WMLog error:"Failed to parse " + condition + " as legitimate derived qualifier"]; return }
    var sourceKeyPath    = yn[1];
    var operator         = yn[2];
    var subqueryOperator = yn[3];
    var targetKeyPath    = yn[4];

    var recd = [model entityClassDescriptionForEntityNamed:entity];
    var sourceGoo = [recd parseKeyPath:sourceKeyPath withSQLExpression:sqlExpression andModel:model];
    var rhs = targetKeyPath;

    if ([WMUtility expressionIsKeyPath:targetKeyPath]) {
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
            [WMLog debug:"Couldn't find alias for column " + sourceGoo.TARGET_ATTRIBUTE];
        }
    }
    var lhs = tableAlias + "." + columnName;
    return [WMSQLStatement newWithSQL:[lhs, operator, subqueryOperator, rhs].join(" ") andBindValues:bindValues];
}

- hasSubQuery {
    return ([self subQuery] ? true : false);
}

- subQuery {
    var bven = [bindValues objectEnumerator], bv;
    while (bv = [bven nextObject]) {
        if (bv.isa && [bv isKindOfClass:WMFetchSpecification]) {
            return bv;
        }
    }
    return nil;
}

@end


// qualifier subclasses

@implementation WMBooleanQualifier : WMQualifier
{
    id subqualifiers @accessors;
}

+ newWithType:(id)type qualifiers:(id)quals {
    var q = [[self alloc] initWithType:type];
    var qs = [WMArray arrayFromObject:quals];
    // don't allow these qualifiers without subqualifiers
    if (!qs || [qs count] == 0) { return nil };
    if ([qs count] == 1) { return [qs objectAtIndex:0]; }
    var validQualifiers = [WMArray new];
    for (var i=0; i < qs.length ; i++) {
        var cq = qs[i];
        if (!cq) { continue }
        [validQualifiers addObject:cq];
    }
    [q setSubqualifiers:validQualifiers];
    return q;
}

- (id) description {
    var d = "<WMQualifier [ " + entity + " ] - " + type + " " + [self subqualifiers] + ">";
    return d;
}

- setEntity:(id)e {
    var sqe = [subqualifiers objectEnumerator], sq;
    while (sq = [sqe nextObject]) {
        [sq setEntity:e];
    }
    entity = e;
}

- (WMSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model andClause:(id)clause {
    var subqualifierSQL = [WMArray new];
    var subqualifierBindValues = [WMArray new];
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
    return [WMSQLStatement newWithSQL:qualifierAsSQL andBindValues:subqualifierBindValues];
}

@end

//-------------------------------------------------------------
@implementation WMAndQualifier : WMBooleanQualifier

+ (WMQualifier) newWithQualifiers:(id)qualifiers {
    return [self newWithType:"AND" qualifiers:qualifiers];
}

@end
//-------------------------------------------------------------

//-------------------------------------------------------------
@implementation WMOrQualifier : WMBooleanQualifier

+ newWithQualifiers:(id)qualifiers {
    return [self newWithType:"AND" qualifiers:qualifiers];
}

@end
//-------------------------------------------------------------


//-------------------------------------------------------------
@implementation WMSQLQualifier : WMQualifier
{
    WMArray bindValues @accessors;
    CPString condition @accessors;
}

+ newWithCondition:(id)condition {
    var q = [[self alloc] initWithType:"SQL"];
    [q setCondition:condition];
    return q;
}

- (WMSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model andClause:(id)clause {
    // short-circuit qualifiers that don't need to be translated.
    // TODO : rework the SQL in these to use the table aliases
    return [WMSQLStatement newWithSQL:condition andBindValues:bindValues];
}

- (id) description {
    var d = "<WMSQLQualifier [ " + entity + " ] - " + [self condition] + " >";
    return d;
}

@end
//-------------------------------------------------------------


//-------------------------------------------------------------
@implementation WMKeyValueQualifier : WMQualifier
{
    WMArray bindValues @accessors;
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
    var args = [WMArray new];
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
    var d = "<WMKeyValueQualifier [ " + entity + " ] - " + [self condition] + " ( " + [self bindValues] + " ) >";
    return d;
}

- requiresRepeatedJoin {
    requiresRepeatedJoin = true;
    return self;
}

- (WMSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model andClause:(id)clause {
    // short-circuit qualifiers that don't need to be translated.
    // TODO : rework the SQL in these to use the table aliases
    //

    // There are three parts to a key-qualifier:
    // 1. key path
    // 2. operator
    // 3. values
    //

    var re = new RegExp("^\\\s*([\\\w\\\._-]+)\\\s*" + QUALWMIER_REGEX + "\\\s*(ANY|ALL|SOME)?(.*)$", "i");
    var yn = condition.match(re);
    if (!yn) {
        [CPException raise:"CPException" reason:"Qualifier condition is not well-formed: " + condition];
        return nil;
    }
    var keyPath = yn[1];
    var operator = yn[2];
    var subqueryOperator = yn[3];
    var value = yn[4];
    //[WMLog dump:[ keyPath, operator, subqueryOperator, value ]];

    var ecd = [model entityClassDescriptionForEntityNamed:entity];
    if (![WMLog assert:ecd message:"Entity class description exists for self.entity for self.condition"]) { return nil; }
    var oecd = ecd;  // original ecd
    var cecd = ecd;  // current ecd

    // Figure out the target ecd for the qualifier by looping through the keys in the path

    var bits = [keyPath componentsSeparatedByString:/\./];

    if ([bits count] == 0) { bits = [keyPath] }

    var qualifierKey;
    var deferredJoins = [WMArray new];

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
            //WM::Log::debug("Using dynamic relationship");
        }

        if (![WMLog assert:relationship message:"Relationship " + qualifierKey + " exists on entity " + [cecd name]]) {
            return [WMSQLStatement newWithSQL:"" andBindValues:[]];
        }
        var tecd = [relationship targetEntityClassDescription:model];

        if (![WMLog assert:tecd message:"Target entity class " + [relationship targetEntity] + " exists"]) {
            return [WMSQLStatement newWithSQL:"" andBindValues:[]];
        }

        //
        // ([tecd isAggregateEntity]) {
        //  // We just bail on it if it's aggregate
        //    // TODO see if there's a way to insert an aggregate qualifier into the key path
        //  //
        //    return [self _translateQualifierWithGoo:
        //            bits[i+1],
        //            relationship,
        //            tecd,
        //            model,
        //            sqlExpression,
        //            operator,
        //            value
        //        ];
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
    [WMLog assert:tableAlias message:"Alias for table tn is tableAlias"];

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
        //    uc([oecd aggregateKeyName]): 1,
        //    uc([oecd aggregateValueName]): 1,
        //    "creationDate": 1,
        //    "modificationDate": 1,
        //};
        //if ([oecd isAggregateEntity]
        //    && !aggregateColumns[uc(columnName)]
        //    && ![oecd _primaryKey]->hasKeyField(uc(columnName))) {
        //    conditionInSQL = "tableAlias + "[.oecd aggregateKeyName].
        //                    " = %@ AND tableAlias + "[.oecd aggregateValueName].
        //                    " operator value";
        //    bindValues = [columnName, @{self._bindValues}];
        //} else {
        //
            //WM::Log::debug("MEOW $value");
            // TODO... I am pretty sure this code is redundant now;
            // the code above takes care of resolving the key paths now.
            //
            if ([WMUtility expressionIsKeyPath:value]) {
                //[WMLog debug:"key path"];
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
        [WMLog debug:"Adding repeated join on " + [dj.ecd name] + " with key " + dj.key];
        [sqlExpression addRepeatedTraversedRelationship:dj.key onEntity:dj.ecd];
    }

    return [WMSQLStatement newWithSQL:conditionInSQL andBindValues:bindValues];
}

@end


@implementation WMMatchQualifier : WMQualifier
{
    WMArray matchAttributes @accessors;
    CPString matchTerms  @accessors;
}

+ newWithAttributes:(id)attributes andTerms:(id)terms {
    var q = [[self alloc] initWithType:"MATCH"];
    var re = new RegExp(",\s*");
    [q setMatchAttributes:[attributes componentsSeparatedByString:re]];
    [q setMatchTerms:terms];
    return q;
}

- (WMSQLStatement)sqlWithBindValuesForExpression:(id)sqlExpression andModel:(id)model andClause:(id)clause {
    var ecd = [model entityClassDescriptionForEntityNamed:entity];
    if (![WMLog assert:ecd message:"Entity class description exists for self.entity"]) { return {}; }
    var oecd = ecd;  // original ecd
    var cecd = ecd;  // current ecd

    // figure out the attributes
    var attributes = matchAttributes ? [matchAttributes copy] : [WMArray new];

    if ([attributes count] == 0) {
        var aten = [[oecd allAttributes] objectEnumerator], attribute;
        while (attribute = [aten nextObject]) {
            if (!attribute.TYPE.match(/(CHAR|TEXT|BLOB)/i)) { continue; }
            [attributes addObject:attribute];
        }
    }

    var mappedAttributes = [WMArray new];

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

    [WMLog dump:"Matching on " + [mappedAttributes componentsJoinedByString:", "]];
    // TODO escape terms here.
    var terms = matchTerms.split(/\s+/);

    return [WMSQLStatement newWithSQL:"MATCH(" + [mappedAttributes componentsJoinedByString:", "] + ") AGAINST (? IN BOOLEAN MODE)"
            andBindValues:[terms componentsJoinedByString:" "]];
}

@end
