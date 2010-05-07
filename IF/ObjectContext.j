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

@import "DB.j"
@import "Log.j"
@import "Entity.j"
@import "Entity/Persistent.j"
@import "Model.j"
@import "FetchSpecification.j"
@import "Qualifier.j"
@import "Entity/UniqueIdentifier.j"
//@import "Cache.j"

var JSON = require("json");
var UTIL = require("util");
var _objectContext;

@implementation IFObjectContext : IFObject {
{
    id shouldUseCache @accessors;
    id model @accessors;

    //---------------------------------------------
    // Experimental!  Adding and tracking entities
    // so that we can add real transactions.
    //---------------------------------------------
    // Entities that have been committed are here
    id _trackedEntities;
    // New entities are here
    id _addedEntities;
    // Entities that have been explicitly 'forgotten'
    // are tracked here; this is to make sure they're
    // not mutated by mistake during cascades
    id _forgottenEntities;
    // Track deleted entities here.  This is pretty
    // simplistic because it doesn't represent the order
    // of operations that are submitted to the ObjectContext;
    // sometimes the order of adds/updates/delete is going
    // to be important :(
    id _deletedEntities;
}

+ new {
    if (_objectContext) { return _objectContext }
    _objectContext = [[self alloc] init];
    [_objectContext loadModel];
    return _objectContext;
}

- init {
    [super init];
    _trackedEntities = {};
    _deletedEntities = {};
    _addedEntities = [];
    _forgottenEntities = [];
    return self;
}

- (void) loadModel {
    model = [IFModel defaultModel];
    if (!model) {
        throw [CPException raise:"CPException" message:"Couldn't load default model into object context"];
    }
}

- entityWithUniqueIdentifier:(id)ui {
    if (!ui) { return nil }
    var e = [ui entityName];
    var eid = [ui externalId];
    return [self entityWithExternalId:eid];
}

- (id) entity:(id)entityName withPrimaryKey:(id)idt {
    if (!idt) { [IFLog debug:"can't fetch " + entityName + " with no id"]; return nil };

    /*
    if ([self hasCachedEntityWithId:id forEntityClass:entityName] && [self shouldUseCache]) {
        [IFLog debug:"Cache hit for entity " + entityName + " with id " + id];
        return [self cachedEntityWithId:id forEntityClass:entityName];
    }
    */
    var entityClassDescription = [model entityClassDescriptionForEntityNamed:entityName];
    if (!entityClassDescription) { return nil };

    var keyQualifier = [[entityClassDescription _primaryKey] qualifierForValue:idt];
    var fetchSpecification = [IFFetchSpecification new:entityName :keyQualifier];
    var entities = [self entitiesMatchingFetchSpecification:fetchSpecification];
    if ([entities count]> 1) {
        [IFLog warning:"Found more than one " + entityName + " matching id " + idt];
        return [entities objectAtIndex:0];
    }
    if ([entities count] == 0) {
        [IFLog warning:"No " + entityName + " matching id " + idt + " found"];
        return;
    }
    var e = [entities objectAtIndex:0];
    return e;
}

- (id) entity:(id)entityName withExternalId:(id)externalId {
    // TODO implement configurable external primary keys
    return [self entity:entityName withPrimaryKey:externalId];
    /*
    if (!externalId) { return nil }
    if (![IFLog assert:
    return null unless IFLog.assert(
        IFUtility.externalIdIsValid(externalId),
        "entityWithExternalId(): externalId='externalId' .. is valid for class name entityName",
    );
    return [self entityWithPrimaryKey:IFUtility.idFromExternalId(externalId)](entityName, IFUtility.idFromExternalId(externalId));
    */
}

// By default new instances aren't tracked.
- newInstanceOfEntity:(id)entityName {
    return [self entity:entityName fromHash:{}];
}

- entity:(id)entityName fromHash:(id)hash {
    if (!entityName) { return nil }
    if (!hash) { return nil }
    var entityClass = objj_getClass(entityName);
    return [entityClass newFromDictionary:hash];
}

- entity:(id)entityName fromRawHash:(id)hash {
    if (!entityName) { return nil }
    if (!hash) { return nil }
    var entityClass = objj_getClass(entityName);
    return [entityClass newFromRawDictionary:hash];
}

- (id)entityArrayFromHashArray:(id)entityName :(id)hashArray {
    if (!entityName) { return [] }
    if (!hashArray) { return [] }
    var entities = [];
    for (var i=0; i < [hashArray count]; i++) {
        entities[entities.length] = [self entity:entityName fromRawHash:[hashArray objectAtIndex:i]];
    }
    return entities;
}

- allEntities:(id)entityName {
    if (!entityName) { return [IFArray new] }
    var fetchSpecification = [IFFetchSpecification new:entityName :nil];
    [fetchSpecification setFetchLimit:0];
    return [self entitiesMatchingFetchSpecification:fetchSpecification];
}

- entities:(id)entityName withPrimaryKeys:(id)entityIds {
    var entityClassDescription = [model entityClassDescriptionForEntityNamed:entityName];
    if (!entityClassDescription) { return nil }

    if ([IFLog assert:![entityClassDescription isAggregateEntity] message:"Entity is not aggregate"]) {
        return [];
    }

    var results = [IFArray new];
    for (var i=0; i<=[entityIds count]; i+=30) {
        var idList = [];
        for (var j=i; j<(i+30); j++) {
            if (!entityIds[j]) { continue }
            idList[idList.length] = entityIds[j];
        }
        var qualifier = [IFSQLQualifier newWithCondition:[[entityClassDescription _primaryKey] stringValue] +
                            " IN (" + idList.join(", ") + ")"]
        var entities = [self entities:entityName matchingQualifier:qualifier];
        [results addObjectsFromArray:entities];
    }
    return results;
}

- entity:(id)entityName matchingQualifier:(id)qualifier {
    var entities = [self entities:entityName matchingQualifier:qualifier];
    if ([entities count] > 1) {
        [IFLog warning:"More than one entity found for entityMatchingQualifier"];
    }
    return [entities objectAtIndex:0];
}

- entities:(id)entityName matchingQualifier:(id)qualifier {
    if (!entityName) {
        [IFLog error:"You must specify an entity type"];
        return nil;
    }
    if (!qualifier) { return nil };
    var fetchSpecification = [IFFetchSpecification new:entityName :qualifier];
    return [self entitiesMatchingFetchSpecification:fetchSpecification];
}

- entityMatchingFetchSpecification:(id)fetchSpecification {
    var entities = [self entitiesMatchingFetchSpecification:fetchSpecification];
    if ([entities count] > 0) {
        return [entities objectAtIndex:0];
    }
    return nil;
}

- (CPArray) entitiesMatchingFetchSpecification:(id)fetchSpecification {
    if (!fetchSpecification) { return [IFArray new] }
    var st = [fetchSpecification toSQLFromExpression];
    //[IFLog debug:st];
    var results = [IFDB rawRowsForSQLStatement:st];
    results = results || [IFArray new];
    var unpackedResults = [fetchSpecification unpackResultsIntoEntities:results inObjectContext:self];
    [IFLog database:"Matched " + [results count] + " row(s), " + [unpackedResults count] + " result(s)"];
    //[IFLog debug:[unpackedResults objectAtIndex:0]];
    [self trackEntities:unpackedResults];
    return unpackedResults;
}

- countOfEntitiesMatchingFetchSpecification:(id)fetchSpecification {
    var result = [[IFDB _driver] countUsingSQL:[fetchSpecification toCountSQLFromExpression]];
    [IFLog database:"Counted " + result + " results"];
    return result;
}

- resultsForSummarySpecification:(id)summarySpecification {
    if (!summarySpecification) { return [IFArray new] }
    var results = [IFDB rawRowsForSQLStatement:[summarySpecification toSQLFromExpression]];
    var unpackedResults = [summarySpecification unpackResultsIntoDictionaries:results];
    [IFLog database:"Summary contained " + [unpackedResults count] + " results"];
    return unpackedResults;
}

- (void) trackEntities:(id)entities {
    for (var i=0; i<[entities count]; i++) {
        [self trackEntity:[entities objectAtIndex:i]];
    }
}

- (void) trackEntity:(id)entity {
    if ([entity isTrackedByObjectContext]) { return }
    if ([entity hasNeverBeenCommitted]) {
        _addedEntities[_addedEntities.length] = entity; 
        [entity awakeFromInsertionInObjectContext:self];
    } else {
        var pkv = [[entity uniqueIdentifier] description]; 
        if (_trackedEntities[pkv]) {
            if (_trackedEntities[pkv] === entity) {
                // this instance is already being tracked
            } else {
                var trackedEntity = _trackedEntities[pkv];
                if ([trackedEntity hasChanged]) {
                    // TODO what to do here?
                    [IFLog error:"Entity " + pkv + " is already tracked by the ObjectContext but instances do not match"];
                }
            } 
        } else {
            _trackedEntities[pkv] = entity;
            [entity awakeFromFetchInObjectContext:self];
        }
    }
    [_forgottenEntities removeObject:entity];
    [entity setTrackingObjectContext:self];
}

- (void) untrackEntity:(id)entity {
    var e = [self trackedInstanceOfEntity:entity];
    if (![_forgottenEntities containsObject:entity]) {
        [_forgottenEntities addObject:entity];
    }
    [_addedEntities removeObject:entity];
    if (![e hasNeverBeenCommitted]) {
        var pkv = [[e uniqueIdentifier] description];
        delete _trackedEntities[pkv];
    }
    [e setTrackingObjectContext:nil];
}

- (Boolean) entityIsTracked:(id)entity {
    var e = [self trackedInstanceOfEntity:entity];
    return Boolean(e);
}

- (id) trackedInstanceOfEntity:(id)entity {
    if ([entity hasNeverBeenCommitted]) {
        // we can't check for it by pk
        if ([_addedEntities containsObject:entity]) { return entity }
        return nil;
    } else {
        var pkv = [[entity uniqueIdentifier] description];
        return _trackedEntities[pkv];
    }
}

// For now there's no real difference between
// inserting it into the ObjectContext and
// tracking stuff that comes from the DB - but
// maybe there will be so I'm adding this
// here.
- (void) insertEntity:(id)entity {
    [self trackEntity:entity];
}

- (void) forgetEntity:(id)entity {
    [self untrackEntity:entity];
}

- deleteEntity:(id)entity {
    // TODO add notifications
    if (![entity isTrackedByObjectContext]) { return }
    if (![entity hasNeverBeenCommitted]) {
        var pkv = [[entity uniqueIdentifier] description]; 
        if (_deletedEntities[pkv]) {
            if (_deletedEntities[pkv] === entity) {
                // this instance is already deleted - ignore
            } else {
                [IFLog error:"Can't delete " + entity + " - object with same PK value has already been deleted"];
            } 
        } else {
            _deletedEntities[pkv] = entity;
        }
    }
}

// These are just here for testing; you generally won't want to use these.
- (id) forgottenEntities { return _forgottenEntities }
- (id) addedEntities { return _addedEntities }
- (id) deletedEntities { return _deletedEntities }

// we need to include _addedEntities here too; from the POV
// outside of the OC, added entities are "tracked" too.
- (id) trackedEntities {
    return _p_values(_trackedEntities).concat(_addedEntities);
}
- (id) changedEntities {
    var changed = [];
    var tes = UTIL.values(_trackedEntities);
    for (var i=0; i<_p_length(tes); i++) {
        var e = _p_objectAtIndex(tes, i);
        if ([e hasChanged]) {
            changed[changed.length] = e;
        }
    }
    return changed;
}

//
- (void) saveChanges {
    [IFLog setLogMask:0xffff];
    // TODO Make transactions optional
    [IFDB startTransaction];
    
    try {
        // Process additions first.
        // For every inserted entity, move it to the _trackedEntities array
        for (var i=0; i < [_addedEntities count]; i++) {
            var ae = _addedEntities[i];
            [ae save];  
        }

        // then updates
        var updatedEntities = UTIL.values(_trackedEntities);
        for (var i=0; i < updatedEntities.length; i++) {
            var ue = updatedEntities[i];
            [ue save];
        }

        // then deletions
        var des = UTIL.values(_deletedEntities);
        for (var i=0; i < des.length; i++) {
            var de = des[i];
            [des _deleteSelf];
        }
    } catch (CPException) {
        [IFDB rollbackTransaction];
        return;
    }

    // I think we succeeded at this point, so
    // move the added entities into the trackedEntities
    // dictionary, clear the deletedEntities out,
    // and do some other housekeeping

    try {
        for (var i=0; i < _addedEntities.length; i++) {
            var entity = _addedEntities[i];
            if ([entity hasNeverBeenCommitted]) {
                // this shouldn't be possible
                throw [CPException raise:"CPException" reason:"Failed to save new object " + entity];
            }
            var pkv = [[entity uniqueIdentifier] description]; 
            if (_trackedEntities[pkv]) {
                // this instance is already being tracked
                throw [CPException raise:"CPException" reason:"Newly saved object seems to be tracked already: " + entity];
            } else {
                _trackedEntities[pkv] = entity;
            }
        }

        for (var i=0; _deletedEntities.length; i++) {
            var entity = _deletedEntities[i];
            if (![entity wasDeletedFromDataStore]) {
                throw [CPException raise:"CPException" reason:"Object should have been deleted but wasn't: " + entity];
            }
        }
    } catch (CPException) {
        [IFDB rollbackTransaction];
        return;
    }

    _addedEntities = [];
    _deletedEntities = {};
    
    // hmmmm, do we really want to flush this?
    _forgottenEntities = [];

    // otherwise, commit the transaction
    [IFDB endTransaction];
    [IFLog debug:UTIL.object.repr(UTIL.keys(_trackedEntities))];
    [IFLog setLogMask:0x0000];
}

@end
