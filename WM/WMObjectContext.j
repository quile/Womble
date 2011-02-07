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

@import "WMDB.j"
@import "WMLog.j"
@import "WMEntity.j"
@import "Entity/WMPersistentEntity.j"
@import "WMModel.j"
@import "WMFetchSpecification.j"
@import "WMQualifier.j"
@import "Entity/WMEntityUniqueIdentifier.j"
//@import "Cache.j"

var JSON = require("json");
var UTIL = require("util");
var _objectContext;

@implementation WMObjectContext : WMObject {
{
    id model @accessors;

    //---------------------------------------------
    // Experimental!  Adding and tracking entities
    // so that we can add real transactions.
    //---------------------------------------------
    id _shouldTrackEntities @accessors;
    id _saveChangesInProgress;

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
    [self _initTrackingStore];
    // Default this to true so entity tracking is turned on
    // for the OC *unless you disable it*
    [self enableTracking];
    _saveChangesInProgress = false;
    return self;
}

- (void) _initTrackingStore {
    _trackedEntities = {};
    _deletedEntities = {};
    _addedEntities = [];
    _forgottenEntities = [];
}

- (void) loadModel {
    model = [WMModel defaultModel];
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
    if (!idt) { [WMLog debug:"can't fetch " + entityName + " with no id"]; return nil };

    // temporary hack - FIXME!
    var uid = [WMEntityUniqueIdentifier newFromString:entityName + "," + idt];
    var tracked = [self trackedInstanceOfEntityWithUniqueIdentifier:uid];
    if (tracked) {
        return tracked;
    }

    var entityClassDescription = [model entityClassDescriptionForEntityNamed:entityName];
    if (!entityClassDescription) { return nil };

    var keyQualifier = [[entityClassDescription _primaryKey] qualifierForValue:idt];
    var fetchSpecification = [WMFetchSpecification new:entityName :keyQualifier];
    var entities = [self entitiesMatchingFetchSpecification:fetchSpecification];
    if ([entities count]> 1) {
        [WMLog warning:"Found more than one " + entityName + " matching id " + idt];
        return [entities objectAtIndex:0];
    }
    if ([entities count] == 0) {
        [WMLog warning:"No " + entityName + " matching id " + idt + " found"];
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
    if (![WMLog assert:
    return null unless WMLog.assert(
        WMUtility.externalIdIsValid(externalId),
        "entityWithExternalId(): externalId='externalId' .. is valid for class name entityName",
    );
    return [self entityWithPrimaryKey:WMUtility.idFromExternalId(externalId)](entityName, WMUtility.idFromExternalId(externalId));
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

- (CPArray) allEntities:(id)entityName {
    if (!entityName) { return [CPArray new] }
    var fetchSpecification = [WMFetchSpecification new:entityName :nil];
    [fetchSpecification setFetchLimit:0];
    return [self entitiesMatchingFetchSpecification:fetchSpecification];
}

- (CPArray) entities:(id)entityName withPrimaryKeys:(id)entityIds {
    var entityClassDescription = [model entityClassDescriptionForEntityNamed:entityName];
    if (!entityClassDescription) { return nil }

    if ([WMLog assert:![entityClassDescription isAggregateEntity] message:"Entity is not aggregate"]) {
        return [];
    }

    var results = [CPArray new];
    for (var i=0; i<=[entityIds count]; i+=30) {
        var idList = [];
        for (var j=i; j<(i+30); j++) {
            if (!entityIds[j]) { continue }
            idList[idList.length] = entityIds[j];
        }
        var qualifier = [WMSQLQualifier newWithCondition:[[entityClassDescription _primaryKey] stringValue] +
                            " IN (" + idList.join(", ") + ")"]
        var entities = [self entities:entityName matchingQualifier:qualifier];
        [results addObjectsFromArray:entities];
    }
    return results;
}

- entity:(id)entityName matchingQualifier:(id)qualifier {
    var entities = [self entities:entityName matchingQualifier:qualifier];
    if ([entities count] > 1) {
        [WMLog warning:"More than one entity found for entityMatchingQualifier"];
    }
    return [entities objectAtIndex:0];
}

- entities:(id)entityName matchingQualifier:(id)qualifier {
    if (!entityName) {
        [WMLog error:"You must specify an entity type"];
        return nil;
    }
    if (!qualifier) { return nil };
    var fetchSpecification = [WMFetchSpecification new:entityName :qualifier];
    return [self entitiesMatchingFetchSpecification:fetchSpecification];
}

- (id)entityMatchingFetchSpecification:(id)fetchSpecification {
    var entities = [self entitiesMatchingFetchSpecification:fetchSpecification];
    if ([entities count] > 0) {
        return [entities objectAtIndex:0];
    }
    return nil;
}

- (CPArray) entitiesMatchingFetchSpecification:(id)fetchSpecification {
    if (!fetchSpecification) { return [CPArray new] }
    var st = [fetchSpecification toSQLFromExpression];
    //[WMLog debug:st];
    var results = [WMDB rawRowsForSQLStatement:st];
    results = results || [CPArray new];
    var unpackedResults = [fetchSpecification unpackResultsIntoEntities:results inObjectContext:self];
    [WMLog database:"Matched " + [results count] + " row(s), " + [unpackedResults count] + " result(s)"];
    //[WMLog debug:[unpackedResults objectAtIndex:0]];
    if (_shouldTrackEntities) {
        [self trackEntities:unpackedResults];
    }
    return unpackedResults;
}

- countOfEntitiesMatchingFetchSpecification:(id)fetchSpecification {
    var result = [[WMDB _driver] countUsingSQL:[fetchSpecification toCountSQLFromExpression]];
    [WMLog database:"Counted " + result + " results"];
    return result;
}

- resultsForSummarySpecification:(id)summarySpecification {
    if (!summarySpecification) { return [WMArray new] }
    var results = [WMDB rawRowsForSQLStatement:[summarySpecification toSQLFromExpression]];
    var unpackedResults = [summarySpecification unpackResultsIntoDictionaries:results];
    [WMLog database:"Summary contained " + [unpackedResults count] + " results"];
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
                    [WMLog error:"Entity " + pkv + " is already tracked by the ObjectContext but instances do not match"];
                }
            }
        } else {
            _trackedEntities[pkv] = entity;
            [entity awakeFromFetchInObjectContext:self];
        }
    }
    [_forgottenEntities removeObject:entity];
    [entity setTrackingObjectContext:self];

    // if the entity that was just added has related
    // entities, we are going to track them too.
    var relatedEntities = [entity relatedEntities];
    for (var i=0; i<relatedEntities.length; i++) {
        [self trackEntity:relatedEntities[i]];
    }
}

- (void) untrackEntity:(id)entity {
    var e = [self trackedInstanceOfEntity:entity] || entity;
    if (![_forgottenEntities containsObject:e]) {
        [_forgottenEntities addObject:e];
    }
    [_addedEntities removeObject:e];
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

- (void) updateTrackedInstanceOfEntity:(id)entity {
    if (_saveChangesInProgress) { return }
    [self untrackEntity:entity];
    [self trackEntity:entity];
}

- (id) trackedInstanceOfEntity:(id)entity {
    if (!entity) { [WMLog error:"Cannot retrieve tracked instance of nil"]; return nil }
    if ([entity hasNeverBeenCommitted]) {
        // we can't check for it by pk
        if ([_addedEntities containsObject:entity]) { return entity }
        return nil;
    } else {
        var pkv = [[entity uniqueIdentifier] description];
        return _trackedEntities[pkv] || _deletedEntities[pkv];
    }
}

- (id) trackedInstanceOfEntityWithUniqueIdentifier:(id)uid {
    return _trackedEntities[[uid description]];
}

// For now there's no real difference between
// inserting it into the ObjectContext and
// tracking stuff that comes from the DB - but
// maybe there will be so I'm adding this
// here.
- (void) insertEntity:(id)entity {
    if (!_shouldTrackEntities) { return }
    [self trackEntity:entity];
}

- (void) forgetEntity:(id)entity {
    if (!_shouldTrackEntities) { return }
    [self untrackEntity:entity];
}

- deleteEntity:(id)entity {
    if (!_shouldTrackEntities) { return }
    // TODO add notifications
    if (![entity isTrackedByObjectContext]) { return }
    if (![entity hasNeverBeenCommitted]) {
        var pkv = [[entity uniqueIdentifier] description];
        if (_deletedEntities[pkv]) {
            if (_deletedEntities[pkv] === entity) {
                // this instance is already deleted - ignore
            } else {
                [WMLog error:"Can't delete " + entity + " - object with same PK value has already been deleted"];
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
    return _p_values(_trackedEntities).concat(_addedEntities).concat(_p_values(_deletedEntities));
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

- (void) enableTracking {
    _shouldTrackEntities = true;
}

- (void) disableTracking {
    _shouldTrackEntities = false;
}

- (id) trackingIsEnabled {
    return _shouldTrackEntities;
}

- (void) saveChanges {
    if (!_shouldTrackEntities) {
        throw [CPException raise:"CPException" reason:"Can't call saveChanges on an ObjectContext that is not tracking"];
    }

    // TODO Make transactions optional
    [WMDB startTransaction];
    _saveChangesInProgress = true;

    try {
        // Process additions first.
        var aes = _addedEntities;
        for (var i=0; i < [aes count]; i++) {
            var ae = aes[i];
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
        [WMDB rollbackTransaction];
        return;
    }

    // I think we succeeded at this point, so
    // move the added entities into the trackedEntities
    // dictionary, clear the deletedEntities out,
    // and do some other housekeeping

    // NOTE: none of the exceptions thrown here are
    // likely ever to occur; conceivably they could,
    // and we need to check for them, but in general
    // this code shouldn't throw.
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
        [WMDB rollbackTransaction];
        _saveChangesInProgress = false;
        return;
    }

    _addedEntities = [];
    _deletedEntities = {};

    // hmmmm, do we really want to flush this?
    _forgottenEntities = [];

    // otherwise, commit the transaction
    [WMDB endTransaction];


    _saveChangesInProgress = false;
    [WMLog debug:UTIL.object.repr(UTIL.keys(_trackedEntities))];
}

- (void) clearTrackedEntities {
    var all = [self trackedEntities];
    for (var i=0; i<all.length; i++) {
        [self untrackEntity:all[i]];
    }
    [self _initTrackingStore];
}

@end
