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
//@import "Cache.j"

var JSON = require("json");
var _objectContext;

@implementation IFObjectContext : IFObject {
{
    id shouldUseCache @accessors;
    id model @accessors;
}


+ new {
    if (_objectContext) { return _objectContext }

/*	var self = { _cachedEntitiesByEntityClass: {},
				 _fileCache => IF::Cache::cacheOfTypeWithName("MemCached", "Entities"),
  				 _shouldUseCache => 1,
			 };
	bless self, className;
	unless (self._model) {
		IFLog.error("Error loading default model into ObjectContext, application is not initialized");
		return null;
	}
	_objectContext = self;
	return self;
   */
    _objectContext = [[self alloc] init];
    [_objectContext loadModel];
    return _objectContext;
}

- loadModel {
	model = [IFModel defaultModel];
    if (!model) {
        return [CPException raise:"CPException" message:"Couldn't load default model into object context"];
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
    //[IFLog debug:keyQualifier];
	var fetchSpecification = [IFFetchSpecification new:entityName :keyQualifier];
    //[IFLog debug:fetchSpecification];
	var entities = [self entitiesMatchingFetchSpecification:fetchSpecification];
	if ([entities count]> 1) {
		[IFLog warning:"Found more than one " + entityName + " matching id " + idt];
		return [entities objectAtIndex:0];
	}
	if ([entities count] == 0) {
		[IFLog warning:"No " + entityName + " matching id " + idt + " found"];
		return;
	}
	return [entities objectAtIndex:0];
}

- entity:(id)entityName withExternalId:(id)externalId {
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

- newInstanceOfEntity:(id)entityName {
	return [self entity:entityName fromHash:{}];
}

- entity:(id)entityName fromHash:(id)hash {
    if (!entityName) { return nil }
    if (!hash) { return nil }
	//var entityClass = [[self model] entityNamespace] + "::entityName";
    var entityClass = objj_getClass(entityName);
	return [entityClass newFromDictionary:hash];
}

- entity:(id)entityName fromRawHash:(id)hash {
    if (!entityName) { return nil }
    if (!hash) { return nil }
	//var entityClass = [[self model] entityNamespace] + "::entityName";
    var entityClass = objj_getClass(entityName);
	return [entityClass newFromRawDictionary:hash];
}
/*
- entityArrayFromHashArray:(id)hashArray {
	return null unless entityName;
	return null unless hashArray;
	var entityClass = [self model]->entityNamespace() + "::entityName";
	var entityArray =[];
	for var e (@hashArray) {
		push (@entityArray, [entityClass new:%{e}](%{e}));
	}
	return entityArray;
}
*/
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
	//[self addEntities:results toCache] if self->shouldUseCache();
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
	return [entities objectAtIndex:0];
}

- (CPArray) entitiesMatchingFetchSpecification:(id)fetchSpecification {
	if (!fetchSpecification) { return [IFArray new] }
    var st = [fetchSpecification toSQLFromExpression];
    //[IFLog debug:st];
	var results = [IFDB rawRowsForSQLStatement:st];
    results = results || [IFArray new];
	var unpackedResults = [fetchSpecification unpackResultsIntoEntities:results]; //[self addEntities:unpackedResults toCache] if self->shouldUseCache();
	[IFLog database:"Matched " + [results count] + " row(s), " + [unpackedResults count] + " result(s)"];
    //[IFLog debug:[unpackedResults objectAtIndex:0]];
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

// TODO move all this stuff into the object context instead
// of being on the entity
- deleteEntity:(id)entity {
	[entity _deleteSelf];
}

/*
- clearCachedEntities {
	self._cachedEntitiesByEntityClass = {};
	IFLog.debug("Cached entities cleared");
}

- hasCachedEntityWithId:(id)id forEntityClass:(id)entityClass {
	return 1 if self._cachedEntitiesByEntityClass->{entityClass}->{id};
	return 0;
}

- cachedEntityWithId:(id)id forEntityClass:(id)entityClass {
	return self._cachedEntitiesByEntityClass->{entityClass}->{id};
}

- cachedEntitiesOfClass:(id)entityClass {
	return self._cachedEntitiesByEntityClass->{entityClass};
}

- addEntity:(id)entity toCache {
	self._cachedEntitiesByEntityClass->{[entity _entityClassName]}->{entity->id()} = entity;
	IFLog.debug("Added entity entity to cache");
}

- addEntities:(id)entities toCache {
	foreach var entity (@entities) {
		[self addEntity:entity toCache];
	}
}
*/

@end
