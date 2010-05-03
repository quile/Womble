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

@import "Application.j"
@import "Object.j"
@import "DB.j"
@import "Log.j"
@import "EntityClassDescription.j"

var UTIL = require("util");

var _defaultModel;

@implementation IFModel : IFObject
{
    id _entityClassDescriptionCache;
    CPString entityNamespace @accessors;
    id entityClassDictionary;
    id model;
}

/*=========================================== */

+ entityClassDescriptionClassName { return "IFEntityClassDescription" };

- init {
    [super init];
    _entityClassDescriptionCache = {};
    return self;
}

- initWithModelAtPath:(id)modelPath {
    [self init];
	//[IFLog debug:"Loading in model found at " + modelPath];
	var m = require(modelPath);
	if (!m) {
		[IFLog error:"Cannot load model " + modelPath +
                     " - This is fatal unless it's the first " +
                     "time you're generating the model"];
		return nil;
	} else {
        //[IFLog debug:"Loaded data: " + m.toString()];
    }
    return [self initWithModelData:m.MODEL];
}

- (IFModel) initWithModelData:(id)modelData {
    [self init];
    model = modelData;

	/* by this point we have an empty model. */

    [self populateModel];

	/* Instantiate entity class descriptions for every entity type,
	   which forces the class to cache each one
    */
	for (entityClass in model.ENTITIES) {
		[IFLog debug:"Caching entity class description for " + entityClass];
		var entityClassDescription = [self entityClassDescriptionForEntityNamed:entityClass];
	}
	[IFLog debug:"Loaded and populated model"];
	return self;
}

+ defaultModel {
	return _defaultModel;
}

+ setDefaultModel:(id)model {
	_defaultModel = model;
}

- entityRoot {
    return null;
}

- entityRecordForKey:(id)key {
	return [self entityClassDescriptionForEntityNamed:key];
}

- entityClassDescriptionForEntityNamed:(id)entityName {
    if (_entityClassDescriptionCache[entityName])
        return _entityClassDescriptionCache[entityName]

    var ecdClassName = [[self class] entityClassDescriptionClassName];
    /* if ecdClassName doesn't exist, this will yack, but that's ok
       because if this ain't workin', ain't nothin' workin'.
    */
    var ecdClass = objj_getClass(ecdClassName);
    // create a new ecd object and populate it with data from the model
    var entityClassDescription = [[ecdClass alloc] initWithModelData:model.ENTITIES[entityName]];
    if (!entityClassDescription) {
        [IFLog debug:"Couldn't load ecd " + entityName];
        return;
    }
    [entityClassDescription setName:entityName];
    _entityClassDescriptionCache[entityName] = entityClassDescription;
    return entityClassDescription;
}

- entityClassDescriptionForTable:(id)table {
    for (en in model.ENTITIES) {
        var ecd = model.ENTITIES[en];
        if (ecd.TABLE == table) { return ecd; }
    }
    return nil;
}

- relationshipWithName:(id)relationshipName onEntity:(id)entityName {
	var entity = [self entityRecordForKey:entityName];
    if (!entity) { return nil; }
	var relationships = [entity relationships];
    if (!relationships) { return nil; }
	return relationships[relationshipName];
}

- allEntityClassKeys {
	return UTIL.keys(_entityClassDescriptionCache);
}

- populateModel {
    [self subclassResponsibility:"Your model class must implement populateModel()"];
}

@end
