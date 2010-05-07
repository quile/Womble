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


@import <Foundation/CPKeyValueCoding.j>
@import "../Entity.j"

var UTIL = require("util");
// these are utils to make the move to JS
// from perl a bit easier; they should be cleaned up
// and ultimately removed once the port is working.
@import "../Helpers.js"

@implementation IFPersistentEntity : IFEntity
{
    id __storedValues;
    id __joinRecordForRelationship;
    id __uniqueIdentifier;
    id __isMarkedForSave;
    id __trackingObjectContext;

    // TODO - clean up this naming!
    id _wasDeletedFromDataStore;
    id _relatedEntities;
    id _RELATIONSHIP_HINTS;
    id _columnKeyMap;
    id _currentStoredRepresentation;
    id _isPartiallyInflated;
    id _wasDeletedFromDataStore;
}

+ instanceWithId:(id)id {
    if (!id) { return nil }
    return [[IFObjectContext new] entity:e withPrimaryKey:id];
}

+ instanceWithExternalId:(id)externalId {
    if (!externalId) { return nil }
    return [[IFObjectContext new] entity:e withExternalId:id];
    /*
    if (![IFLog assert:[IFUtility.externalIdIsValid(externalId)] message:"instanceWithExternalId(): externalId='externalId' .. is valid for className",
    )  { return nil }
    return [className instanceWithId:IFUtility.idFromExternalId(externalId)];
    */
}

+ instanceWithName:(id)name {
    if (!name) { return nil }
    return [[IFObjectContext new] entity:entityName matchingQualifier:[IFKeyValueQualifier key:'name = %@', name]];
}

+ newFromRawDictionary:(id)d {
    return [[super alloc] initWithRawDictionary:d];
}

- init {
    [super init];
    __storedValues = {};
    __joinRecordForRelationship = {};
    __uniqueIdentifier = nil;
    __isTrackedByObjectContext = false;
    _wasDeletedFromDataStore = false;
    _columnKeyMap = {};
    _relatedEntities = {};
    _RELATIONSHIP_HINTS = {};
    _currentStoredRepresentation = nil;
    _isPartiallyInflated = false;
    return self;
}

// This is used to perform low-level inflation of an entity,
// like during fetching from a DB.  It bypasses the
// KVC machinery and sets values directly using their
// low-level column values.
- (void) initWithRawDictionary:(id)d {
    [self init];
    [self initStoredValuesWithDictionary:d];
    [self markAllStoredValuesAsClean];    // flush the dirty bits for those values
    return self;
}

// TODO: fix this primary key nonsense
- is:(id)other {
    if (!other) { return false }

    var primaryKey = [[[self entityClassDescription] _primaryKey] asString].toUpperCase();
    if (![self storedValueForRawKey:primaryKey]) {
        return false;
    }
    return ([self storedValueForRawKey:primaryKey] == [other storedValueForRawKey:primaryKey]);
}

- (id) relationshipNamed:(id)relationshipName {
    if (![self entityClassDescription]) { return nil }
    return [[self entityClassDescription] relationshipWithName:relationshipName];
}

- (IFFetchSpecification) fetchSpecificationForFlattenedToManyRelationshipNamed:(id)relationshipName {
    var relationship = [self relationshipNamed:relationshipName];
    if (![self storedValueForRawKey:[relationship sourceAttribute]]) {
        return nil;
    }

    var targetEntity = [[IFModel defaultModel] entityClassDescriptionForEntityNamed:[relationship targetEntity]];
    var qualifiers = [];

    if ([relationship qualifier]) {
        qualifiers[qualifiers.length] = [relationship qualifier]
    }

    var fetchSpecification = [IFFetchSpecification new:[relationship targetEntity] :nil :nil];
    [fetchSpecification setFetchLimit:nil];

    var sqlExpression = [fetchSpecification sqlExpression];
    // this is bogus... it shouldn't be here... all of this relationship
    // traversal stuff needs to be encapsulated properly.
    var targetTable = [targetEntity _table];
    //unless (targetTable) {
    //    targetTable = targetEntity.AGGREGATE_TABLE;
    //}
    if (targetTable) {
        [sqlExpression addTable:targetTable];
    }
    [sqlExpression addTable:[relationship joinTable]];
    [sqlExpression addTableToFetch:[relationship joinTable]];

    if ([relationship hints]) {
        // force it to fetch the id of the join table record, which
        // should suffice for uniquing these rows if this relationship
        // is altered/saved again:
        [sqlExpression addColumn:"ID" forTable:[relationship joinTable]];
        for (var i=0; i < [relationship hints].length; i++) {
            [sqlExpression addColumn:[relationship hints][i] forTable:[relationship joinTable]];
        }
    }
    if ([relationship defaultSortOrderings]) {
        var sortOrderings = [];
        for (var i=0; i < [relationship defaultSortOrderings]; i++) {
            sortOrderings[sortOrderings.length] = [relationship defaultSortOrderings][i];
        }
        [fetchSpecification setSortOrderings:sortOrderings];
    }

    var sourceAttributeValue = [self storedValueForRawKey:[relationship sourceAttribute]];
    var sourceAttribute = [[self entityClassDescription] attributeForColumnName:[relationship sourceAttribute]];
    if (sourceAttribute && sourceAttribute['TYPE'].match(/CHAR/i)) {
        sourceAttributeValue = [IFDB quote:sourceAttributeValue];
    }
    qualifiers[qualifiers.length] = [IFSQLQualifier newWithCondition:
                [sqlExpression aliasForTable:targetTable] + "." +
                [relationship targetAttribute] + " = " +
                [sqlExpression aliasForTable:[relationship joinTable]] + "." +
                [relationship joinSourceAttribute]];
    qualifiers[qualifiers.length] = [IFSQLQualifier newWithCondition:
                [sqlExpression aliasForTable:[relationship joinTable]] + "." +
                [relationship joinTargetAttribute] + " = " + sourceAttributeValue];

    if ([relationship joinQualifiers]) {
        for (var joinQualifierAttribute in [relationship joinQualifiers]) {
            var joinQualifierValue = [relationship joinQualifiers][joinQualifierAttribute];
            if (!joinQualifierValue.match(/^\d+$/)) {
                joinQualifierValue = [IFDB quote:joinQualifierValue];
            }
            qualifiers[qualifiers.length] = [IFQualifier new:"SQL",    [sqlExpression aliasForTable:[relationship joinTable] + "." + joinQualifierAttribute + "=" + joinQualifierValue]]
        }
    }

    qualifiers.concat([self additionalQualifiersForRelationshipNamed:relationshipName]);
    [fetchSpecification setQualifier:[IFQualifier and:qualifiers]];
    return fetchSpecification;
}

// TODO: These methods are actually not named right; they don't add the
// entity to both sides.  The methods were named this way because
// the EOF methods were named this way, but I've never actually
// gotten around to implementing the whole cycle.
- addObject:(id)object toBothSidesOfRelationshipWithKey:(id)relationshipName {
    /* I >think< this should blank out any previous relationship hints
       if it has any:
    */
    if (object) { [object _deprecated_setRelationshipHints:nil] }
    [self addObject:object toBothSidesOfRelationshipWithKey:relationshipName andHints:{}];
}

- addObject:(id)object toBothSidesOfRelationshipWithKey:(id)relationshipName andHints:(id)hints {
    if (!(object && object.isa && [object isKindOfClass:IFPersistentEntity])) {
        [IFLog error:"Invalid object passed to addObjectToBothSidesOfRelationshipWithKey: " + object];
        return;
    }

    var relationship = [self relationshipNamed:relationshipName];
    if (![IFLog assert:relationship message:"Relationship relationshipName exists"]) { return }

    if ([relationship type] == "TO_ONE") {
        [self setValue:object ofToOneRelationshipNamed:relationshipName];
        return;
    }

    /* TODO un-deprecate this! */
    [object _deprecated_setRelationshipHints:hints];
    [self _addCachedEntities:[object] toRelationshipNamed:relationshipName];

    /* if the relationship requires a join table entry, stash the
       hints as part of a to-be-created join table entry, and
       we're done for now
    */
    if ([relationship type] == "FLATTENED_TO_MANY") {
        [object __setJoinRecord:hints forEntity:self throughFlattenedToManyRelationshipNamed:relationshipName];
        return;
    }

    /* if neither object has been committed, we're done for now */
    if ([self hasNeverBeenCommitted] && [object hasNeverBeenCommitted]) { return }

    /* otherwise, let's figure out if we can set some IDs */

    var objectPrimaryKey = [[[object entityClassDescription] _primaryKey] asString].toUpperCase();
    var primaryKey = [[[self entityClassDescription] _primaryKey] asString].toUpperCase();
    var targetAttribute = [relationship targetAttribute].toUpperCase();
    var sourceAttribute = [relationship sourceAttribute].toUpperCase();

    /* this object has been committed */
    if (![self hasNeverBeenCommitted]) {
        /* TODO look up the primary key by *attribute* not column */

        // FIXME comparing directly is lame and really only works
        // for simple pks.
        if (primaryKey == sourceAttribute) {
            /* This means this object is committed already *AND*
               the other object is expecting the id of this one to
               complete the relationship
            */
            [object setStoredValue:[self storedValueForRawKey:sourceAttribute] forRawKey:targetAttribute];
        }
    }

    /* related object has been committed */
    if (![object hasNeverBeenCommitted]) {
        /* TODO look up the primary key by *attribute* not column */
        if (primaryKey != sourceAttribute) {
            [self setStoredValue:[object storedValueForRawKey:targetAttribute] forRawKey:sourceAttribute];
        }
    }
}

- removeObject:(id)object fromBothSidesOfRelationshipWithKey:(id)relationshipName {
    return [self removeObject:object fromBothSidesOfRelationshipWithKey:relationshipName andHints:{}];
}

- removeObject:(id)obj fromBothSidesOfRelationshipWithKey:(id)relationshipName andHints:(id)hints {
    var relationship = [self relationshipNamed:relationshipName];
    if (!relationship) { return }

    [self _removeCachedEntities:[obj] fromRelationshipNamed:relationshipName];
    var objectPrimaryKey = [[[obj entityClassDescription] _primaryKey] asString].toUpperCase();
    var primaryKey = [[[self entityClassDescription] _primaryKey] asString].toUpperCase();

    if ([relationship type] == "FLATTENED_TO_MANY") {
        /* make sure we have something to associate: */
        if (![obj storedValueForRawKey:objectPrimaryKey]) { return }
        if (![self storedValueForRawKey:primaryKey]) { return }

        var qualifiers = [];
        qualifiers[qualifiers.length] = [relationship joinTargetAttribute] + " = " + [self storedValueForRawKey:primaryKey];
        qualifiers[qualifiers.length] = [relationship joinSourceAttribute] + " = " + [obj storedValueForRawKey:objectPrimaryKey];

        // go through the hints too
        for (var key in hints) {
            var value = hints[key];
            if (!value.match(/^\d+$/)) {
                value = [IFDB quote:value];
            }
            qualifiers[qualifiers.length] = key + " = " + value;
        }
        if ([relationship joinQualifiers]) {
            for (var key in [relationship joinQualifiers]) {
                var value = [relationship joinQualifiers][value];
                if (!value.match(/^\d+$/)) {
                    value = [IFDB quote:value];
                }
                qualifiers[qualifiers.length] = key + " = " + value;
            }
        }
        var sql = "DELETE FROM " + [relationship joinTable] + " WHERE " + qualifiers.join(" AND ");
        [IFDB executeArbitrarySQL:sql];
        /* FIXME how do I get the errors?
        eval {
            var e = IFDB.dbConnection()->errstr;
            IFLog.error(e) if e;
        };
        */
        if ([self __joinRecordForEntity:obj throughFlattenedToManyRelationshipNamed:relationshipName]) {
            [self __setJoinRecord:nil forEntity:obj throughFlattenedToManyRelationshipNamed:relationshipName];
            [IFLog debug:"Blanked out join record from self to object"];
        }
    }
}


- removeAllObjectsFromBothSidesOfRelationshipWithKey:(id)relationshipName {
    var relationship = [self relationshipNamed:relationshipName];
    if (![IFLog assert:relationship message:"Relationship " + relationshipName + " doesn't exist on entity " + self]) { return }
    var qualifiers = [];
    var primaryKey = [[self entityClassDescription] _primaryKey];
        qualifiers[qualifiers.length] = [relationship joinTargetAttribute] + " = " + [self storedValueForRawKey:primaryKey];
    if ([relationship joinQualifiers]) {
        for (var key in [relationship joinQualifiers]) {
            var value = [relationship joinQualifiers][value];
            if (!value.match(/^\d+$/)) {
                value = [IFDB quote:value];
            }
            qualifiers[qualifiers.length] = key + " = " + value;
        }
    }
    var sql = "DELETE FROM " + [relationship joinTable] + " WHERE " + qualifiers.join(" AND ");
    [IFDB executeArbitrarySQL:sql];
    [self _clearCachedEntitiesForRelationshipNamed:relationshipName];
}

- targetEntityClassForRelationshipNamed:(id)relationshipName {
    var relationship = [self relationshipNamed:relationshipName];
    return [relationship targetEntity];
}

- _table {
    return [[self entityClassDescription] _table];
}

- _entityClassName {
    return _entityClassName;
}

- countOfEntitiesForRelationshipNamed:(id)relationshipName {
    var relationship = [self relationshipNamed:relationshipName];
    if (!relationship) {
        [IFLog warning:"Can't find " + relationshipName];
        return nil;
    }
    var objectContext = [IFObjectContext new];
    var fetchSpecification;
    if ([relationship type] != "FLATTENED_TO_MANY") {
        fetchSpecification = [self fetchSpecificationForToOneOrToManyRelationshipNamed:relationshipName];
    } else {
        fetchSpecification = [self fetchSpecificationForFlattenedToManyRelationshipNamed:relationshipName];
    }
    if (!fetchSpecification) { return 0 }
    return [objectContext countOfEntitiesMatchingFetchSpecification:fetchSpecification];
}

- entitiesForRelationshipNamed:(id)relationshipName {
    var relationship = [self relationshipNamed:relationshipName];
    if (!relationship) {
        [IFLog warning:"Can't find relationship named " + relationshipName + " on entity class " + [[self entityClassDescription] name]];
        return nil;
    }
    var objectContext = [IFObjectContext new];
    var entities = [];
    if ([relationship type] != "FLATTENED_TO_MANY") {
        // check for something we can short-cut
        if ([relationship type] == "TO_ONE") {
            var targetEntityDescription = [[IFModel defaultModel] entityClassDescriptionForEntityNamed:[relationship targetEntity]];
            if (!targetEntityDescription) {
                [IFLog error:"Attempted to traverse relationship " + relationshipName + " to non-existent entity " + [relationship targetEntity]];

            }
            if ([relationship targetAttribute].toUpperCase() == [[targetEntityDescription _primaryKey] asString].toUpperCase()) {
                var entities = [objectContext entity:[relationship targetEntity] withPrimaryKey:[self storedValueForRawKey:[relationship sourceAttribute]]];
                return [IFArray arrayFromObject:entities];
            }
        }

        var fsObject = [self fetchSpecificationForToOneOrToManyRelationshipNamed:relationshipName];
        entities = [objectContext entitiesMatchingFetchSpecification:fsObject];
        return entities;
    } else {
        var fs = [self fetchSpecificationForFlattenedToManyRelationshipNamed:relationshipName];
        if (!fs) {
            return [IFArray new];
        }
        var entities = [objectContext entitiesMatchingFetchSpecification:fs];

        if ([relationship hints]) {
            // if a hint record showed up here, add a join record if appropriate
            for (var i=0; i < [entities count]; i++) {
                var entity = [entities objectAtIndex:i];
                var hints = [entity _deprecated_relationshipHints];

                if (hints['ID']) {
                    [IFLog debug:"Fetched an entity with hints stored in db row with id " + hints['ID']];
                    [self __setJoinRecord:hints forEntity:entity throughFlattenedToManyRelationshipNamed:relationshipName];
                }
            }
        }
        return entities;
    }
}


- (IFFetchSpecification) fetchSpecificationForToOneOrToManyRelationshipNamed:(id)relationshipName {
    var relationship = [self relationshipNamed:relationshipName];
    if (![self storedValueForRawKey:[relationship sourceAttribute]]) {
        //IF::Log::warning("Attempt to create fetch specification for relationship named \"$relationshipName\" on $self failed: source attribute ".$relationship->{SOURCE_ATTRIBUTE}." is null");
        return nil;
    }

    var targetEntity = [[IFModel defaultModel] entityClassDescriptionForEntityNamed:[relationship targetEntity]];
    var qualifiers = [];
    qualifiers[qualifiers.length] = [IFKeyValueQualifier key:[relationship targetAttribute] + " = %@", [self storedValueForRawKey:[relationship sourceAttribute]]];

    if ([relationship qualifier]) {
        qualifiers[qualifiers.length] = [relationship qualifier];
    }

    qualifiers.concat([self additionalQualifiersForRelationshipNamed:relationshipName]);
    var fs = [IFFetchSpecification new:[relationship targetEntity] :[IFQualifier and:qualifiers] :[relationship defaultSortOrderings]];
    [fs setFetchLimit:0];
    return fs;
}

- additionalQualifiersForRelationshipNamed:(id)relationshipName {
    return [];
}

- entityForRelationshipNamed:relationshipName {
    /* TODO: This is shorthand, but I really should write a special
       case for this.  Instead we need to rely on the return
       values from entitiesForRelationshipNamed().
    */
    var result =  [self entitiesForRelationshipNamed:relationshipName];
    var results = [IFArray arrayWithObject:result];
    if ([results count] > 0) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- entityWithId:(id)id inEntityArray:(id)entityArray {
    for (var i=0; i < [entityArray count]; i++) {
        var entity = [entityArray objectAtIndex:i];
        if ([entity id] == id) { return entity }
    }
    return nil;
}

- faultEntityForRelationshipNamed:(id)relationshipName {
    var entities = [self faultEntitiesForRelationshipNamed:relationshipName];
    [IFLog assert:[entities isKindOfClass:CPArray] message:"Relationship returned an array"];
    if ([entities count] > 0) {
        // FIXME maybe this should throw; finding more than one entity is a bug?
        return [entities objectAtIndex:0];
    }
    return nil;
}


- faultEntitiesForRelationshipNamed:(id)relationshipName {
    if (![self _hasCachedEntitiesForRelationshipNamed:relationshipName]) {
        var entities = [self entitiesForRelationshipNamed:relationshipName];
        [self _setCachedEntities:entities forRelationshipNamed:relationshipName];
    }
    return [self _cachedEntitiesForRelationshipNamed:relationshipName];
}

- invalidateEntitiesForRelationshipNamed:(id)relationshipName {
    [IFLog debug:"Invalidating entities for faulted relationship " + relationshipName];
    [self _clearCachedEntitiesForRelationshipNamed:relationshipName];
}

/* removes all entities for a given relationship
   ok, smartypants, don't try to optimise this by deleting rows
   directly from the tables; this is a generic deletion method
   that removes objects by calling their "deleteSelf" method.
   That's the only correct way to remove an object UNLESS you
   know something special about it.
*/
- deleteAllEntitiesForRelationshipNamed:(id)relationshipName {
    var entityArray = [self entitiesForRelationshipNamed:relationshipName];
    if (!entityArray) { return }
    for (var i=0; i < [entityArray objectAtIndex:i]; i++) {
        [entity _deleteSelf];
    }
    [self _clearCachedEntitiesForRelationshipNamed:relationshipName];
}

- removeAllEntitiesForRelationshipDirectlyFromDatabase:(id)relationshipName {
    var relationship = [self relationshipNamed:relationshipName];
    if (!relationship) { return }
    var sourceAttribute = [self storedValueForKey:[relationship sourceAttribute]];
    var tecd = [[IFModel defaultModel] entityClassDescriptionForEntityNamed:[relationship targetEntity]];
    if (!tecd) { return }
    var table = [tecd _table];
    /* The T0 is there to assist the SQL gen engine in the qualifier generation
       if qualifiers are needed:
    */
    var query = "DELETE FROM table WHERE " + [relationship targetAttribute] + "=" + [IFDB quote:sourceAttribute]; // TODO this will only ever work in MySQL because of the quoting.
    if ([relationship qualifier]) {
        var q = [relationship qualifier];
        [q setEntity:[[self entityClassDescription] name]];
        var se = [IFSQLExpression new];
        [se addEntityClassDescription:[self entityClassDescription]];
        // FIXME don't use default model
        var goo = [q sqlWithBindValuesForExpression:se andModel:[IFModel defaultModel]];

        /* this hack is gnarly: we generate the SQL for the qualifier, then strip off the goo
           pertaining to the table alias, since table aliases don't work in DELETE statements
        */
        var hack = [goo sql];
        hack.replace(/T[0-9]+\./gi, "");
        query = query + " AND " + hack;

        var st = [IFSQLStatement newWithSQL:query andBindValues:[goo bindValues]];
        return;
    }
    [IFDB executeArbitrarySQL:query];
}

- save {
    [self save:"NOW"];
}

- save:(id)when {
    when = when || "NOW";
    // These lines ensure that an object that is already in the "to-be-saved"
    // stack doesn't try to save itself again (which will catch circular
    // saves where A tries to save B, which tries to save A).

    // TODO: this will only work when you have circular references that are
    // in-memory.  It won't work if the objects aren't "uniqued" correctly,
    // which could still happen easily.
    if (__isMarkedForSave) { return }
    __isMarkedForSave = true;

    if (![self isValidForCommit]) {
        __isMarkedForSave = false;
        return;
    }
    var entityClassDescription = [self entityClassDescription];

    // First, check all the cached related entities and see
    // if any of them need to be committed
    var relationships = [entityClassDescription relationships];
    var pko = [entityClassDescription _primaryKey];
    var primaryKey = [pko asString].toUpperCase();
    for (var relationshipName in relationships) {
        var relationship = [entityClassDescription relationshipWithName:relationshipName];
        if ([relationship isReadOnly]) { continue }
        if (!([relationship type] == "TO_ONE" &&
              [relationship sourceAttribute].toUpperCase() != primaryKey)) { continue }

        for (var i=0; i < [[self _cachedEntitiesForRelationshipNamed:relationshipName] count]; i++) {
            var entity = [[self _cachedEntitiesForRelationshipNamed:relationshipName] objectAtIndex:i];
            if (!entity) {
                [IFLog error:"Undefined entity in " + relationshipName + " on " + [entityClassDescription name]];
                continue;
            }
            [entity save];
            [self setStoredValue:[entity storedValueForRawKey:[relationship targetAttribute]] forRawKey:[relationship sourceAttribute]];
        }
    }

    // Allow the object a chance to react before being committed to the DB
    [self prepareForCommit];
    //[self invokeNotification:"willBeSaved" fromObject:self withArguments:[]];

    // we really need to have all field names
    // stored in the model so we can pull those and
    // ONLY those from the entity

    var dataRecord = {};
    dataRecord[ primaryKey ] = [self storedValueForRawKey:primaryKey];

    var allAttributeNames = [entityClassDescription allAttributeNames];
    for (var i=0; i < [allAttributeNames count]; i++) {
        var k = [allAttributeNames objectAtIndex:i];
        if ([self storedValueForKeyHasChanged:k]) {
            [IFLog debug:k + " has changed to " + [self storedValueForKey:k]];
        } else {
            continue;
        }
        var columnName = [entityClassDescription columnNameForAttributeName:k];
        dataRecord[columnName] = [self storedValueForKey:k];
    }

    if (UTIL.keys(dataRecord).length > 1) {
        [IFLog debug:UTIL.object.repr(dataRecord)];
        // This lets the DB layer fish around the ecd for info.  It's a
        // major kludge.
        dataRecord._ecd = entityClassDescription;
        if (when == "LATER" && ![self hasUnsavedRelatedEntities]) {
            [IFDB updateRecord:dataRecord inTable:[self _table] :"DELAYED"];
        } else {
            [IFDB updateRecord:dataRecord inTable:[self _table] :""];
        }
        _currentStoredRepresentation = nil;
        [self didCommit];
        //[self invokeNotification:"wasSaved" fromObject:self withArguments:""];

        // check for a new ID
        if (![self id]) {
            [self setId:dataRecord[primaryKey]];
        }
        [self markAllStoredValuesAsClean];
    } else {
        [IFLog debug:self  + ": save ignored, no attributes set."];
    }

    // now that we've committed the object, we can
    // fix relationships
    for (var relationshipName in relationships) {
        var relationship = [entityClassDescription relationshipWithName:relationshipName];
        if ([relationship isReadOnly]) { continue }
        var targetAttribute = [relationship targetAttribute].toUpperCase();
        var sourceAttribute = [relationship sourceAttribute].toUpperCase();
        if ([relationship type] == "TO_ONE" && sourceAttribute != primaryKey) { continue };
        for (var i=0; i < [[self _deletedEntitiesForRelationshipNamed:relationshipName] count]; i++) {
            var deletedEntity = [[self _deletedEntitiesForRelationshipNamed:relationshipName] objectAtIndex:i];
            [deletedEntity _deleteSelf];
        }

        for (var i=0; i < [[self _removedEntitiesForRelationshipNamed:relationshipName] count]; i++) {
            var entity = [[self _removedEntitiesForRelationshipNamed:relationshipName] objectAtIndex:i];
            [IFLog debug:"Should remove entity"];
            if ([relationship type] == "TO_MANY") {
                // if it's a to-many, we need to blank out the FK
                if ([relationship type] == "TO_ONE" || [relationship type] == "TO_MANY") {

                    if (sourceAttribute == primaryKey) {
                        [entity setStoredValue:0 forRawKey:targetAttribute];
                        [entity save]; // this should blank it out; you need to delete it yourself
                    } // TODO blank out to-one relationship here
                } // elsif ([relationship type] == "FLATTENED_TO_MANY") {
            }
        }

        for (var i=0; i < [[self _cachedEntitiesForRelationshipNamed:relationshipName] count]; i++) {
            var entity = [[self _cachedEntitiesForRelationshipNamed:relationshipName] objectAtIndex:i];
            if ([relationship type] == "TO_ONE" || [relationship type] == "TO_MANY") {
                [entity setStoredValue:[self storedValueForRawKey:sourceAttribute] forRawKey:targetAttribute];
                [entity save:when];
            } else if ([relationship type] == "FLATTENED_TO_MANY") {
                [IFLog debug:"Flattened to-many"];
                //IF::Log::debug("Checking if we need to commit entity $entity");
                // TODO fix this handling:  right now it automatically tries to commit
                // records here, even if they don't need to be committed
                if ([entity hasNeverBeenCommitted]) {
                    [entity save];
                }
                // build a join record for the join table
                // this enhancement checks for the use of a primary key
                // and resolves it through the primary key object itself.
                // This is half-assed and we need a better way to do it
                // everywhere.
                var joinTarget;
                var joinSource;

                if (sourceAttribute == primaryKey) {
                    joinTarget = [pko valueForEntity:self];
                } else {
                    joinTarget = [self storedValueForRawKey:sourceAttribute];
                }

                var tecd = [entity entityClassDescription];
                var tpko = [tecd _primaryKey];
                var tpk  = [tpko asString].toUpperCase();

                if (targetAttribute == tpk) {
                    joinSource = [tpko valueForEntity:entity];
                } else {
                    joinSource = [entity storedValueForRawKey:targetAttribute];
                }
                [IFLog dump:{ "sa":sourceAttribute, "ta":targetAttribute, "jt":joinTarget, "js":joinSource, "pk":primaryKey, "tpk":tpk, "sid":[self id], "eid":[entity id], }];

                // the join record should be updated if it already exists,
                //   and inserted if it doesn't

                var rh = [entity _deprecated_relationshipHints] || {};

                var jr = [entity __joinRecordForEntity:self throughFlattenedToManyRelationshipNamed:relationshipName] || {};
                var rhs = UTIL.update(UTIL.copy(jr), rh);

                var record = {};
                record[ [relationship joinTargetAttribute] ] = joinTarget;
                record[ [relationship joinSourceAttribute] ] = joinSource;
                record = UTIL.update(record, rhs);
                [IFLog dump:record];
                [IFDB updateRecord:record inTable:[relationship joinTable]];

                [entity _deprecated_setRelationshipHints:record];

                if (UTIL.keys(rhs).length) {
                    // blank out the hints and push the join record into holding for later use if necessary.
                    [self _deprecated_setRelationshipHints:nil];
                    [entity __setJoinRecord:record forEntity:self throughFlattenedToManyRelationshipNamed:relationshipName];
                }
                // if this has a reciprocal relationship, we need to set it there too, in case
                // the other object gets saved separately.
                var rrn;
                if (rrn = [relationship reciprocalRelationshipName]) {
                    [entity _addCachedEntities:[self] toRelationshipNamed:rrn];
                    [self __setJoinRecord:record forEntity:entity throughFlattenedToManyRelationshipNamed:[relationship reciprocalRelationshipName]];
                }
            }
        }

        delete _relatedEntities[relationshipName]['removedEntities'];
        delete _relatedEntities[relationshipName]['deletedEntities'];
    }
    __isMarkedForSave = false;
}


/* This private API is so that an in-memory entity knows
   that it has been related to another entity while living
   in memory.  This >IS NOT< for determining database
   relationships, just whether or not the known relationship
   exists and has been established by being saved to the DB.
   Why?  Because if entity A is "added" to a relationship on
   entity B, and entity B is saved, entity A is saved too
   and a join record is created.  If entity B is saved again,
   entity A needs to know that it doesn't need to create
   a join record again.
   Furthermore, if entity A is related to both B and C, and
   entities B and C are BOTH related to entity D, then
   entity D needs to know it's related to BOTH entities B
   and C even though they're all saved in the same call
   to save().
*/

- __joinRecordForEntity:(id)entity throughFlattenedToManyRelationshipNamed:(id)relationshipName {
    var k = entity._UID + ":" + [entity id];
    /* if there's none for this entity, return one for an uncommitted entity
       or an empty hash.
    */
    if (!__joinRecordForRelationship[relationshipName]) { return {} };
    return __joinRecordForRelationship[relationshipName][k]
        || __joinRecordForRelationship[relationshipName][entity._UID + ":"];
}

- __setJoinRecord:(id)record forEntity:(id)entity throughFlattenedToManyRelationshipNamed:(id)relationshipName {
    var k = entity._UID + ":" + [entity id];
    __joinRecordForRelationship[relationshipName] = __joinRecordForRelationship[relationshipName] || {};
    __joinRecordForRelationship[relationshipName][k] = record;
}

- hasUnsavedRelatedEntities {
    var ecd = [self entityClassDescription];
    if (!ecd) { return false };

    var relationships = [ecd relationships];
    var primaryKey = [ecd _primaryKey];

    for (var relationshipName in relationships) {
        var relationship = [entityClassDescription relationshipWithName:relationshipName];
        if ([relationship type] == "TO_ONE" &&
            [relationship sourceAttribute].toUpperCase() != [primaryKey asString].toUpperCase()) { continue }

        for (var i=0; i < [[self _cachedEntitiesForRelationshipNamed:relationshipName] count]; i++) {
            var entity = [[self _cachedEntitiesForRelationshipNamed:relationshipName] objectAtIndex:i];
            if ([relationship type] == "TO_ONE" || [relationship type] == "TO_MANY") {
                if ([entity hasChanged] || [entity hasNeverBeenCommitted]) {
                    return true;
                }
            } else if ([relationship type] == "FLATTENED_TO_MANY") {
                // FIXME: really?
                return true;
            }
        }
    }
    return false;
}


/* this should get overridden in a subclass */
- isValidForCommit {
    return true;
}

- canBeDeleted {
    return [self canBeDeleted:nil];
}

- canBeDeleted:(id)visitedObjects {
    visitedObjects = visitedObjects || {};
    visitedObjects[self._UID] = true; // mark it as visited, to avoid infinite recursion
    for (var relationshipName in [[self entityClassDescription] relationships]) {
        var relationship = [self relationshipNamed:relationshipName];
        if (!(relationship && [relationship deletionRule])) { continue }
        if ([relationship deletionRule] == "DENY") {
            var entities = [self faultEntitiesForRelationshipNamed:relationshipName];
            if ([entities count]) {
                [IFLog warning:"Can't delete object " + self + " because relationship " + relationshipName + " contains entities"];
                return false;
            }
        } else if ([relationship deletionRule] == "CASCADE") {
            var entities = [self faultEntitiesForRelationshipNamed:relationshipName];
            for (var i=0; i < [entities count]; i++) {
                var entity = [entities objectAtIndex:i];
                if (visitedObjects[entity]) { continue }
                if ([entity canBeDeleted:visitedObjects]) { continue }
                [IFLog warning:"Deletion of entity " + self + " is not possible because related entity " + entity + " cannot be deleted"];
                return false;
            }
        }
    }
    return true;
}

- willBeDeleted {
    //[self invokeDelegateMethodNamed:"willBeDeleted"];
}

- _deleteSelf {
    if ([self wasDeletedFromDataStore] || [self hasNeverBeenCommitted]) {
        [IFLog warning:"Can't delete " + self + ", object has never been committed or has already been deleted"];
        return;
    }
    if (![self canBeDeleted]) {
        [IFLog warning:"Can't delete " + self];
        return;
    }

    // Apply cascading delete rules
    var entitiesToDelete = [self entitiesForDeletionByRules];
    var objectContext = [IFObjectContext new];
    for (var i=0; i < [entitiesToDelete count]; i++) {
        var entityToDelete = [entitiesToDelete objectAtIndex:i];
        [objectContext deleteEntity:entityToDelete];
    }

    // check relationships for NULLIFY rules
    for (var relationshipName in [[self entityClassDescription] relationships]) {
        var relationship = [self relationshipNamed:relationshipName];
        if (!(relationship && [relationship deletionRule])) { continue }
        if ([relationship isReadOnly]) { continue }
        [IFLog debug:">>> deleting relationship " + relationshipName];
        if ([relationship deletionRule] == "FORCED_REMOVAL") {
            [self removeAllEntitiesForRelationshipDirectlyFromDatabase:relationshipName];
        } else if ([relationship deletionRule] == "NULLIFY") {
            if ([relationship type] == "FLATTENED_TO_MANY") {
                [self removeAllObjectsFromBothSidesOfRelationshipWithKey:relationshipName];
            } else {
                // for now only allow NULLIFY for relationships that link to this entity's PK:
                if ([relationship sourceAttribute].toUpperCase() ==
                    [[[self entityClassDescription] _primaryKey] asString].toUpperCase()) {
                    var es = [self entitiesForRelationshipNamed:relationshipName];
                    for (var i=0; i < [es count]; i++) {
                        var entity = [es objectAtIndex:i];
                        [entity setStoredValue:nil forRawKey:[relationship targetAttribute]];
                        [entity save];
                    }
                }
            }
        }
    }

    // FIXME don't use the ID here; change it to use _primaryKey etc.
    [IFLog debug:"==> _deleteSelf() called for " + self + ", destroying record with ID " + [self storedValueForRawKey:"ID"]];
    [self willBeDeleted];
    [IFDB deleteRecord:self fromTable:[self _table]];
    _wasDeletedFromDataStore = true;
}


- entitiesForDeletionByRules {
    var entitiesForDeletion = [IFArray new];
    for (var relationshipName in [[self entityClassDescription] relationships]) {
        var relationship = [self relationshipNamed:relationshipName];
        if (!(relationship && [relationship deletionRule])) { continue }
        if ([relationship deletionRule] != "CASCADE") { continue }

        var entities = [self faultEntitiesForRelationshipNamed:relationshipName];
        if ([entities count]) {
            [entitiesForDeletion addObjectsFromArray:entities];
        }
    }
    return entitiesForDeletion;
}

/*
- creationDate {
    var d = [IFDateUnix new:self->storedValueForKey("creationDate")](self->storedValueForKey("creationDate"));
    [d _setOriginFormat:self->entityClassDescription()->attributeWithName("creationDate")->{TYPE}](self->entityClassDescription()->attributeWithName("creationDate")->{TYPE});
    return d;
}

+ setCreationDate:(id)value {
    if (ref(value) && UNIVERSAL::isa(value, "IFDateUnix")) {
        value = [value utc];
    }
    [self setStoredValueForKey:"creationDate"](value, "creationDate");
}

- modificationDate {
    var d = [IFDateUnix new:self->storedValueForKey("modificationDate")](self->storedValueForKey("modificationDate"));
    [d _setOriginFormat:self->entityClassDescription()->attributeWithName("modificationDate")->{TYPE}](self->entityClassDescription()->attributeWithName("modificationDate")->{TYPE});
    return d;
}
*/

- _deprecated_setRelationshipHints:(id)value {
    _RELATIONSHIP_HINTS = value;
}

- _deprecated_relationshipHints {
    if (!_RELATIONSHIP_HINTS) {
        _RELATIONSHIP_HINTS = {};
    }
    return _RELATIONSHIP_HINTS;
}

- _deprecated_relationshipHintForKey:(id)key {
    return [self _deprecated_relationshipHints][key];
}

- _deprecated_setRelationshipHint:(id)value forKey:(id)key {
    [self _deprecated_relationshipHints][key] = value;
}


- entityClassDescription {
    /* don't cache this locally to keep our objects smaller when they're serialised */
    // FIXME don't use default model here
    var en = [self entityClassName];
    var ecd = [[IFModel defaultModel] entityClassDescriptionForEntityNamed:en];
    return ecd;
}

// yikes
/* TODO - find out how to re-bless an object in JS.
- changeEntityClassToClassNamed:(id)newEntityClassName {
    bless self, newEntityClassName;
    var namespace = newEntityClassName;
    namespace =~ s/::([A-Za-z0-9]*)$//g;
    self._entityClassName = 1;
    self._namespace = namespace;
    return self;
}
*/
- addEntities:(id)entities toRelationship:(id)relationshipName {
    [self _addCachedEntities:entities toRelationshipNamed:relationshipName];
}

- addEntity:(id)entity toRelationship:(id)relationshipName {
    [self _addCachedEntities:[entity] toRelationshipNamed:relationshipName];
}


- setValue:(id)entity ofToOneRelationshipNamed:(id)relationshipName {
    var relationship = [[self entityClassDescription] relationshipWithName:relationshipName];
    if (![IFLog assert:relationship message:"Relationship " + relationshipName + " exists"]) { return }

    var targetEntityClass = [[IFModel defaultModel] entityClassDescriptionForEntityNamed:[relationship targetEntity]];
    var objectPrimaryKey = [[targetEntityClass _primaryKey] asString].toUpperCase();
    var primaryKey = [[[self entityClassDescription] _primaryKey] asString].toUpperCase();
    var targetAttribute = [relationship targetAttribute].toUpperCase();
    var sourceAttribute = [relationship sourceAttribute].toUpperCase();

    var deletionRequired = (primaryKey == sourceAttribute);
    var currentEntities = [self entitiesForRelationshipNamed:relationshipName];

    if (deletionRequired) {
        // move them to the "deleted" array
        var deletedEntities = [self _deletedEntitiesForRelationshipNamed:relationshipName];
        [deletedEntities addObjectsFromArray:currentEntities];
        [self _setDeletedEntities:deletedEntities forRelationshipNamed:relationshipName];
    } else {
        // move them to the "removed" array
        var removedEntities = [self _removedEntitiesForRelationshipNamed:relationshipName];
        [removedEntities addObjectsFromArray:currentEntities];
        [self _setRemovedEntities:removedEntities forRelationshipNamed:relationshipName];
    }

    /* clear what's there and add the new one
      $self->_clearCachedEntitiesForRelationshipNamed($relationshipName);
    */
    [self _setCachedEntities:[] forRelationshipNamed:relationshipName];
    if (entity) {
        [self _addCachedEntities:[entity] toRelationshipNamed:relationshipName];

        // if neither object has been committed, we're done for now
        if ([self hasNeverBeenCommitted] && [entity hasNeverBeenCommitted]) { return }

        // this object has been committed
        if (![self hasNeverBeenCommitted]) {
            // TODO look up the primary key by *attribute* not column
            if (primaryKey == sourceAttribute) {
                /* This means this object is committed already *AND*
                   the other object is expecting the id of this one to
                   complete the relationship
                */
                [entity setStoredValue:[self storedValueForRawKey:sourceAttribute] forRawKey:targetAttribute];
            }
        }

        /* related object has been committed */
        if (![entity hasNeverBeenCommitted]) {
            /* TODO look up the primary key by *attribute* not column */
            if (primaryKey != sourceAttribute) {
                [self setStoredValue:[entity storedValueForRawKey:targetAttribute] forRawKey:sourceAttribute];
            }
        }
    } else {
        if (!deletionRequired) {
            [self setStoredValue:0 forRawKey:sourceAttribute];
        }
    }
}


/*----------------------------------------------
   This stuff needs some HEAVY optimisation
   and really should be abstracted somehow
*/

/* dangerous: maybe make this private? */
- setId:(id)value {
    [self setStoredValue:value forKey:"id"];
}

// FIXME: don't hardcode id; use _primaryKey
- id {
    return [self storedValueForKey:"id"];
}

// you subclass this to provide your own scheme
- (id) externalId {
    return [self id];
}

- initStoredValuesWithDictionary:(id)storedValueDictionary {
    /* TODO : This is kinda a hack to get around inflation from
       an existing entity.  When the entity is passed into the
       constructor, it gets dereferenced and converted to a hash
       so the best way to tell if it's an entity is to check for
       its stored values.
    */
    //[IFLog debug:"Initialising with stored values"];
    //[IFLog debug:_p_length(_p_keys(storedValueDictionary)) + " keys"];
    var sten = [storedValueDictionary keyEnumerator], key = nil;
    while (key = [sten nextObject]) {
        var value = [storedValueDictionary objectForKey:key];
        //[IFLog debug:"value " + value + " for key " + key];
        [self setStoredValue:value forRawKey:key];
    }
    return self;
}

- storedKeys {
    return UTIL.keys(__storedValues);
}

- storedValueForKey:(id)key {
    key = key + ""; // coerce to a string
    var rawKey = [self __rawKeyForKey:key];
    //[IFLog debug:key + " -> " + rawKey];
    return [self storedValueForRawKey:rawKey];
}

- (id)__rawKeyForKey:(id)key {
    key = key + ""; // coerce to a string
    var ecd = [self entityClassDescription];
    if (!ecd) {
        [IFLog error:"No entity class description found for " + self + " trying to set key " + key];
        return;
    }
    var col = [ecd columnNameForAttributeName:key];
    if (!col) {
        // FIXME: throw error here?
        [IFLog error:"No column name found for " + key + " on entity " + self];
        return nil;
    }
    return col.toUpperCase();
}

- storedValueForRawKey:(id)key {
    key = key + ""; // coerce to a string
    return [self __storedValueGutsForKey:key]['v'];
}

- setStoredValue:(id)value forKey:(id)key {
    key = key + ""; // coerce to a string
    var newKey = [self __rawKeyForKey:key];
    _columnKeyMap[key] = newKey;
    [IFLog debug:"Setting " + newKey + " to " + value];
    [self setStoredValue:value forRawKey:newKey];
}

- setStoredValue:(id)value forRawKey:(id)key {
    key = key + ""; // coerce to a string
    //key = [[self entityClassDescription] columnNameForAttributeName:key].toUpperCase();
    //[IFLog debug:"Setting value " + value + " for raw key " + key];
    var svg = [self __storedValueGutsForKey:key];
    if (!(svg['v'] && value == svg['v'])) {
        if (!svg['o'] && svg['v']) {
            svg['o'] = svg['v'];
        }
        svg['v'] = value;
        svg['d'] = true;
    }
}

// TODO implement history instead of just saving the last
- revertToSaved {
    for (var key in __storedValues) {
        var svg = [self __storedValueGutsForKey:key];
        if (!svg['o']) { continue }
        svg['v'] = svg['o'];
        delete svg['o'];
    }
    [self markAllStoredValuesAsClean];
}

- revertToSavedValueForKey:(id)key {
    [self revertToSavedValueForRawKey:key];
}

- revertToSavedValueForRawKey:(id)key {
    key = key + ""; // coerce to a string
    key = [self __rawKeyForKey:key];
    var svg = [self __storedValueGutsForKey:key];
    if (!svg['o']) {
        [IFLog warning:"Attempt to revert to saved value for key " + key + " failed because there is no saved value"];
        return;
    }
    svg['v'] = svg['o'];
    delete svg['o'];
    delete svg['d'];
}


- storedValueForKeyHasChanged:(id)key {
    key = key + ""; // coerce to a string
    var columnName = [self __rawKeyForKey:key];
    var svg = [self __storedValueGutsForKey:columnName];
    if (!svg['d']) { return false }
    return true;
}

- keysForAllAlteredStoredValues {
    var alteredStoredValues = [IFArray new];
    var keys = [self storedKeys];
    for (var i=0; i < [keys count]; i++) {
        var key = [keys objectAtIndex:i];
        var svg = [self __storedValueGutsForKey:key];
        if (svg['d']) {
            [alteredStoredValues addObject:key];
        }
    }
    return alteredStoredValues;
}

- markAllStoredValuesAsClean {
    for (var key in __storedValues) {
        var svg = [self __storedValueGutsForKey:key];
        delete svg['d'];
    }
}

- markAllStoredValuesAsDirty {
    var keys = [self storedKeys];
    for (var i=0; i < [keys count]; i++) {
        var key = [keys objectAtIndex:i];
        var svg = [self __storedValueGutsForKey:key];
        svg['d'] = true;
    }
}

- hasChanged {
    var keys = [self storedKeys];
    for (var i=0; i < [keys count]; i++) {
        var key = [keys objectAtIndex:i];
        var svg = [self __storedValueGutsForKey:key];
        if (svg['d']) { return true }
    }
    return false;
}

- (id) __storedValues {
    return __storedValues;
}

/*
- shallowCopy {
    var keyValuePairs = {};
    foreach var key (@{[self storedKeys]}) {
        keyValuePairs[key] = self.__storedValues[key]{v};
    }
    var copy = ref(self)->new(%keyValuePairs);
    [copy markAllStoredValuesAsDirty];
    return copy;
}
*/

/* This method bypasses any caching and fetches the current
   stored state of this entity in the DB.  Useful for
   checking for changes, unindexing, etc.
*/
- currentStoredRepresentation {
    if ([self hasNeverBeenCommitted]) { return nil };
    if (_currentStoredRepresentation) { return _currentStoredRepresentation };
    var objectContext = [IFObjectContext new];
    var isUsingCache = [objectContext shouldUseCache];
    [objectContext setShouldUseCache:true];
    var entity = [objectContext entityWithPrimaryKey:_entityClassName :[self id]];
    [objectContext setShouldUseCache:isUsingCache];
    _currentStoredRepresentation = entity;
    return entity;
}

/*-------- low level in-memory relationship management ------ */

- _hasCachedEntitiesForRelationshipNamed:(id)relationshipName {
    _relatedEntities[relationshipName] = _relatedEntities[relationshipName] || {};
    var es = _relatedEntities[relationshipName]['entities'];
    if (es && _p_isArray(es) && _p_length(es) > 0) { return true };
    var res = _relatedEntities[relationshipName]['removedEntities'];
    if (res && _p_isArray(res) && _p_length(res) > 0) { return true };
    return false;
}

- _cachedEntitiesForRelationshipNamed:(id)relationshipName {
    _relatedEntities[relationshipName] = _relatedEntities[relationshipName] || {};
    return _relatedEntities[relationshipName]['entities'] || [];
}

- _setCachedEntities:(id)entities forRelationshipNamed:(id)relationshipName {
    _relatedEntities[relationshipName] = _relatedEntities[relationshipName] || {};
    _relatedEntities[relationshipName]['entities'] = entities;
}

- _clearCachedEntitiesForRelationshipNamed:(id)relationshipName {
    _relatedEntities[relationshipName] = _relatedEntities[relationshipName] || {};
    delete _relatedEntities[relationshipName];
}

- _addCachedEntities:(id)entities toRelationshipNamed:(id)relationshipName {
    _relatedEntities[relationshipName] = _relatedEntities[relationshipName] || {};
    if (!_relatedEntities[relationshipName]['entities']) {
        _relatedEntities[relationshipName]['entities'] = [];
    }
    for (var i=0; i < entities.length; i++) {
        _relatedEntities[relationshipName]['entities'].push(entities[i]);
    }
}

- _removedEntitiesForRelationshipNamed:(id)relationshipName {
    _relatedEntities[relationshipName] = _relatedEntities[relationshipName] || {};
    return _relatedEntities[relationshipName]['removedEntities'] || [];
}

- _setRemovedEntities:(id)entities forRelationshipNamed:(id)relationshipName {
    _relatedEntities[relationshipName] = _relatedEntities[relationshipName] || {};
    _relatedEntities[relationshipName]['removedEntities'] = entities;
}

- _deletedEntitiesForRelationshipNamed:(id)relationshipName {
    _relatedEntities[relationshipName] = _relatedEntities[relationshipName] || {};
    return _relatedEntities[relationshipName]['deletedEntities'] || [];
}

- _setDeletedEntities:(id)entities forRelationshipNamed:(id)relationshipName {
    _relatedEntities[relationshipName] = _relatedEntities[relationshipName] || {};
    _relatedEntities[relationshipName]['deletedEntities'] = entities;
}

- _removeCachedEntities:(id)entities fromRelationshipNamed:(id)relationshipName {
    _relatedEntities[relationshipName] = _relatedEntities[relationshipName] || {};
    var filteredEntities = [IFArray new];
    var relatedEntities = [IFArray arrayFromObject:[self _cachedEntitiesForRelationshipNamed:relationshipName]];
    var removedEntities = [IFArray arrayFromObject:[self _removedEntitiesForRelationshipNamed:relationshipName]];
    var es = [IFArray arrayFromObject:entities];
    var en = [es objectEnumerator];
    var entity;
    while (entity = [en nextObject]) {
        var ren = [relatedEntities objectEnumerator];
        while (relatedEntity = [ren nextObject]) {
            if (relatedEntity == entity || [entity is:relatedEntity]) {
                [removedEntities addObject:entity];
                continue;
            }
            [filteredEntities addObject:relatedEntity];
        }
        relatedEntities = filteredEntities;
        filteredEntities = [IFArray new];
    }
    [self _setRemovedEntities:removedEntities forRelationshipNamed:relationshipName];
    [self _setCachedEntities:relatedEntities forRelationshipNamed:relationshipName];
}

/*-------- notifications ---------- */
- prepareForCommit {
    //[self invokeDelegateMethodNamed:"prepareForCommit"];
}

- didCommit {
    //[self invokeDelegateMethodNamed:"didCommit"];
}

// FIXME: use primaryKey instead of id
- hasNeverBeenCommitted {
    if ([self id]) { return false }
    return true;
}

- wasDeletedFromDataStore {
    return _wasDeletedFromDataStore;
}

- uniqueIdentifier {
    return [IFEntityUniqueIdentifier newFromEntity:self];
}

// HELP!
- (id)__storedValueGutsForKey:(id)key {
    if (!__storedValues[key]) {
        __storedValues[key] = { 'o': nil, 'd': false, 'v': nil };
    } /* else {
        [IFLog dump:__storedValues[key]];
    } */
    return __storedValues[key];
}

- (void)setIsPartiallyInflated:(id)value {
    _isPartiallyInflated = value;
}

- (id)isPartiallyInflated {
    return _isPartiallyInflated;
}

- (id)description {
    var d = "<" + [self class] + " { ";
    var keys = _p_keys(__storedValues);
    for (var i=0; i < _p_length(keys); i++) {
        var k = _p_objectAtIndex(keys, i);
        d = d + k + ": " + __storedValues[k]['v'] + ", ";
    }
    d = d + " } >";
    return d;
}

- (IFObjectContext) trackingObjectContext {
    return __trackingObjectContext;
}

- (void) setTrackingObjectContext:value {
    __trackingObjectContext = value;
}

- (id) isTrackedByObjectContext {
    return [self isTrackedByObjectContext:nil];
}

- (id) isTrackedByObjectContext:(id)foo {
    if (!foo) {
        return Boolean(__trackingObjectContext);
    }
    return Boolean(__trackingObjectContext === foo);
}

// This is called the first time an
// **un-committed** entity is added to
// the ObjectContext.
- (void) awakeFromInsertionInObjectContext:(IFObjectContext)oc {

}

// This is called when an already-committed
// object is tracked by the ObjectContext.
- (void) awakeFromFetchInObjectContext:(IFObjectContext)oc {

}

@end
