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

/*=====================================
   FetchSpecification
   Abstracts the workings of SQL
   SELECT statements
   from the app developers
  ======================================
*/

@import "Model.j"
@import "Log.j"
@import "Qualifier.j"
@import "SQLExpression.j"

var UTIL = require("util");

@implementation WMFetchSpecification : WMObject
{
    id entity @accessors;
    id entityClassDescription @accessors;
    id tables @accessors;
    id prefetchingRelationships @accessors;
    id traversedRelationshipAttributes @accessors;
    id distinct @accessors;
    id attributes @accessors;
    id sortOrderings @accessors;
    id fetchLimit @accessors;
    id startIndex @accessors;
    id sqlExpression @accessors;
    id shouldFetchRandomly @accessors;
    id inflateAsInstancesOfEntityNamed @accessors;
    id qualifier;
}

- (id) description {
    var d = "<WMFetchSpecification [" + entity + "] - " + qualifier + ">";
    return d;
}

+ new:(id)type :(id)qualifier {
    return [self new:type :qualifier :[]];
}

+ new:(id)type :(id)qualifier :(id)sortOrderings {
    return [[self alloc] initWithEntityType:type qualifier:qualifier sortOrderings:sortOrderings];
}

- initWithEntityType:(id)t qualifier:(id)q sortOrderings:(id)so {
    [self init];
    var model = [WMModel defaultModel];
    if (![WMLog assert:model message:"Found a model to work with"]) { return }
    var ecd = [model entityClassDescriptionForEntityNamed:t];
    if (![WMLog assert:ecd message:"Has entity class description for " + t]) { return null }

    /* for the purposes of fetching entities, we need to check if the
       entity is an aggregate entity or a regular one, and if it's aggregate,
       use the aggregate entityClassDescription instead
    */

    /* TODO:  Clean this mess up: */
    var template = {
        entity: t,
        entityClassDescription: ecd,
        tables: {},
        prefetchingRelationships: [WMArray new],
        traversedRelationshipAttributes: [WMArray new],
        distinct: 0,
        attributes: [WMArray new],
        sortOrderings: so,
        fetchLimit: [[WMApplication defaultApplication] configurationValueForKey:"DEFAULT_BATCH_SIZE"],
        startIndex: 0,
        sqlExpression: [WMSQLExpression new],
        inflateAsInstancesOfEntityNamed: nil,
        shouldFetchRandomly: false
    };

    for (var k in template) {
        [self setValue:template[k] forKey:k];
    }

    /*
    if ([entityClassDescription isAggregateEntity]) {
        // This is what we're fetching, so tell it to fetch the aggregate one
        self._entityClassDescription = [entityClassDescription aggregateEntityClassDescription];
        // This is ultimately what we'll end up with:
        self._rootEntityClassDescription = entityClassDescription;
        self._isAggregateEntity = 1; # not sure if we need this?
    }
    */

    [self setQualifier:q];
    return self;
}

- subqueryForAttributes:(id)attr {
    [self restrictFetchToAttributes:attr];
    [self setFetchLimit:0]; // have to zero the fetch limit for subqueries
    return self;
}

- restrictFetchToAttributes:(id)atts {
    atts = [WMArray arrayFromObject:atts];
    var columnNames = [];
    // FIXME don't rely on default model
    var model = [WMModel defaultModel];
    for (var i=0; i < [atts count]; i++) {
        var attribute = [atts objectAtIndex:i];
        // FIXME generalise this
        if (attribute.match(/\./)) {
            var bits = attribute.split(/\./);
            rn = bits[0];
            a  = bits[1];
            var r = [entityClassDescription relationshipWithName:rn];
            if (r) {
                var recd = [r targetEntityClassDescription];
                if (recd) {
                    var ra = [recd columnNameForAttributeName:a];
                    if (ra) {
                        [self addAttribute:ra forTraversedRelationship:rn];
                    }
                }
            }
        } else {
            columnNames[columnNames.length] = [entityClassDescription columnNameForAttributeName:attribute];
        }
    }
    [self setAttributes:columnNames]; // TODO fix this bent attribute vs. column naming
}

- (id)qualifier {
    return qualifier;
}

// FIXME this is bent; mutating the object when it's set... FIX!
- setQualifier:(id)q {
    qualifier = q;
    if (q) {
        [q setEntity:entity];
    }
}

/* TODO: right now fetch limit and batch size are the same */
- batchSize {
    return fetchLimit;
}

- setBatchSize:(id)value {
    fetchLimit = value;
}

- setStartIndexForNextBatch {
    if (!fetchLimit) { return }
    startIndex += fetchLimit;
}

- setSortOrderings:(id)value {
    sortOrderings = [WMArray arrayFromObject:value];
}

/* Damn, this can only be done once this way.
   TODO: rewrite to allow re-entrant code
*/
- setPrefetchingRelationships:(id)relationships {
    prefetchingRelationships = [WMArray arrayFromObject:relationships];
    for (var i=0; i < [prefetchingRelationships count]; i++) {
        var relationship = [prefetchingRelationships objectAtIndex:i];
        [WMLog debug:"Setting prefetch on relationship '" + relationship + "'"];
        [[self sqlExpression] addPrefetchedRelationship:relationship onEntity:entityClassDescription];
    }
}

- attributes {
    if (attributes && [attributes count] > 0) { return attributes }
    return [[entityClassDescription attributes] allKeys];
}


- attributesForTraversedRelationship:(id)r {
    return traversedRelationshipAttributes[r];
}

- setAttributes:(id)value forTraversedRelationship:(id)r {
    traversedRelationshipAttributes[r] = [WMArray arrayFromObject:value];
}

- addAttribute:(id)a forTraversedRelationship:(id)r {
    var as = [self attributesForTraversedRelationship:r];
    [as addObject:a];
    [self setAttributes:as forTraversedRelationship:r];
}

- addDynamicRelationship:(id)dr withName:(id)name {
    if (![WMLog assert:(dr && name) message:"Adding dynamic relationship with name " + name]) { return };
    /* This is bogus because it has a side-effect of altering the
       dynamic relationship, but that's OK because these are
       supposed to be discarded once used
    */
    [dr setEntityClassDescription:entityClassDescription];
    [dr setName:name];
    [[self sqlExpression] addDynamicRelationship:dr];
}

- buildSQLExpression {
    // FIXME don't use default model
    var model = [WMModel defaultModel];

    var sq = [self sqlExpression];

    [sq setDistinct:distinct];
    [sq setShouldFetchRandomly:shouldFetchRandomly];
    [sq setInflateAsInstancesOfEntityNamed:inflateAsInstancesOfEntityNamed];

    /* populate sql expression:
       1. set the basic root entity class for the fetch.  This also
          populates the table and column lists for this entity
    */
    [sq addEntityClassDescription:entityClassDescription];

    /* 1a. Automatically traverse any dynamic relationships that have been added */
    var dns = [sq dynamicRelationshipNames];
    for (var i=0; i < [dns count]; i++) {
        var rn = [dns objectAtIndex:i];
        [WMLog debug:"Forcing traversal of dynamic relationship " + rn];
        [sq addTraversedRelationship:rn onEntity:entityClassDescription];
    }

    if ([attributes count] > 0) {
        for (var i=0; i < [attributes count] ; i++) {
            var attribute = [attributes objectAtIndex:i];
            [sq onlyFetchColumn:attribute forTable:[entityClassDescription _table]];
        }
    }

    /* aieeee, TODO optimise this so we don't keep doing this everywhere. */
    for (var i=0; i < [traversedRelationshipAttributes count]; i++) {
        var rn = [traversedRelationshipAttributes objectAtIndex:i];
        var r = [entityClassDescription relationshipWithName:rn];
        if (r) {
            var recd = [model entityClassDescriptionForEntityNamed:[r targetEntity]];
            if (recd) {
                var rt = [recd _table];
                for (var j=0; j < [[self attributesForTraversedRelationship:rn] count]; j++) {
                    var a = [[self attributesForTraversedRelationship:rn] objectAtIndex:j];
                    [sq onlyFetchColumn:a forTable:rt];
                }
            }
        }
    }

    [sq addTableToFetch:[entityClassDescription _table]];

    // 1b. Check for mandatory relationships and add them to the prefetch
    var mrs = [entityClassDescription mandatoryRelationships];
    for (var i=0; i < [mrs count]; i++) {
        var mr = [mrs objectAtIndex:i];
        [sq addPrefetchedRelationship:mr onEntity:entityClassDescription];
    }

    /* 2. tell the Qualifier Tree to generate SQL.  This will also
          fill in any traversed relationships that are found
    */
    if ([self qualifier]) {
        var sqlQualifier = [[self qualifier] sqlWithBindValuesForExpression:sq andModel:model];
        [sq setQualifier:[sqlQualifier sql]];
        [sq setQualifierBindValues:[sqlQualifier bindValues]];
        [WMLog debug:"buildSQLExpression - " + [self qualifier]];
    }

    /* 3. Fill in what's left */
    [sq setSortOrderings:sortOrderings];

    /* TODO implement batched fetching for aggregates too.  For now, turn off
       the fetch limit and index
    */
    //unless (self._isAggregateEntity) {
        [sq setFetchLimit:fetchLimit];
        [sq setStartIndex:startIndex];
    //}
}


- toSQLFromExpression {
    [self buildSQLExpression];

    /* Generate the SQL for the whole statement, and return it and
       the bind values ready to be passed to the DB
    */
    return [WMSQLStatement newWithSQL:[[self sqlExpression] selectStatement] andBindValues:[[self sqlExpression] bindValues]];
}

- toCountSQLFromExpression {
    [self buildSQLExpression];

    /* Generate the SQL for the whole statement, and return it and
       the bind values ready to be passed to the DB
    */
    return [WMSQLStatement newWithSQL:[[self sqlExpression] selectCountStatement] andBindValues:[[self sqlExpression] bindValues]];
}

- resolveEntityHash:(id)hash :(id)primaryEntity {
    if (!primaryEntity) { return }
    delete hash[entity];
    for (var entityType in hash) {
        if (entityType == '_RELATIONSHIP_HINTS') {
            [primaryEntity _deprecated_setRelationshipHints:hash[entityType]];
        } else {
            var prefetchedRelationshipName = [[self sqlExpression] relationshipNameForEntityType:entityType];
            if (!prefetchedRelationshipName) { continue };
            var relationship = [entityClassDescription relationshipWithName:prefetchedRelationshipName];
            if (!relationship) {
                relationship = [[self sqlExpression] dynamicRelationshipWithName:prefetchedRelationshipName];
            }
            if (!relationship) { continue };
            // FIXME rewrite these comparisons using [relationship isToOne] etc
            if ([relationship type] == "TO_ONE" || [relationship type] == "TO_MANY") {
                [primaryEntity addEntity:hash[entityType] toRelationship:prefetchedRelationshipName];
                if ([[self attributesForTraversedRelationship:prefetchedRelationshipName] count]) {
                    [hash[entityType] setIsPartiallyInflated:true];
                }
            }
        }
    }
    return primaryEntity;
}


/* This needs to be optimised so that it no longer requires the sort, which is a waste of RAM
   and computation, especially for big lists
*/
- unpackResultsIntoEntities:(id)results inObjectContext:(id)oc {
    var unpackedResults = {};

    var primaryKey = [[entityClassDescription _primaryKey] description].toUpperCase();
    var objectContext = oc || [WMObjectContext new];
    var order = 0;
    var rootEntityClassName = [self inflateAsInstancesOfEntityNamed] || entity;

    if (!entityClassDescription) {
        [CPException raise:"CPException" message:"No entity class description found to unpack"];
    }

    var isFetchingPartialEntity;
    if ([attributes count] < _p_length(_p_keys([entityClassDescription attributes]))) {
        isFetchingPartialEntity = 1;
    }
    for (var i=0; i < [results count]; i++) {
        var result = [results objectAtIndex:i];
        var entityHash = [[self sqlExpression] dictionaryOfEntitiesFromRawRow:result];
        // unique those entities coming in
        var uniqueHash = {};
        for (var entityType in entityHash) {
            var u = [oc trackedInstanceOfEntity:entityHash[entityType]] || entityHash[entityType];
            uniqueHash[entityType] = u;
        }
        var primaryEntity = uniqueHash[rootEntityClassName];
        if (isFetchingPartialEntity) {
            [primaryEntity setIsPartiallyInflated:true];
        }
        var primaryKeyValue = [primaryEntity storedValueForRawKey:primaryKey];
        [WMLog debug:"::: hashing entity with primary key " + primaryKeyValue];
        var existingPrimaryEntityRecord = unpackedResults[primaryKeyValue];
        if (!existingPrimaryEntityRecord) {
            unpackedResults[primaryKeyValue] = {
                ENTITY: primaryEntity,
                ORDER: order,
            };
        } else {
            primaryEntity = existingPrimaryEntityRecord.ENTITY;
        }
        [self resolveEntityHash:uniqueHash :primaryEntity];
        order++;
    }
    var sortedResults = [CPArray new];
    var sortedUnpacked = UTIL.values(unpackedResults).sort(function(a, b) { a.ORDER - b.ORDER });

    for (var i=0; i < sortedUnpacked.length; i++) {
        var result = sortedUnpacked[i];
        [sortedResults addObject:result.ENTITY];
    }
    return sortedResults;
}

- addDerivedDataSource:(id)fs withName:(id)name {
    // This will register it with the sql expression generator and allow for the name
    // to be used within qualifiers
    [[self sqlExpression] addDerivedDataSourceWithDefinition:fs andName:name];
}

- addDerivedDataSource:(id)fs withName:(id)name andQualifier:(id)q {
    [[self sqlExpression] addDerivedDataSourceWithDefinition:fs andName:name];
    [self setQualifier:[WMAndQualifier and:[ qualifier, q ]]];
}

@end
