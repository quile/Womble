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

@import "WMApplication.j"
@import "WMObject.j"
@import "WMDB.j"
@import "WMLog.j"
@import "WMEntityClassDescription.j"

var UTIL = require("util");

var _defaultModel;

@implementation WMModel : WMObject
{
    id _entityClassDescriptionCache;
    CPString entityNamespace @accessors;
    id entityClassDictionary;
    id model;
}

/*=========================================== */

+ entityClassDescriptionClassName { return "WMEntityClassDescription" };

- init {
    [super init];
    _entityClassDescriptionCache = {};
    return self;
}

- initWithModelAtPath:(id)modelPath {
    [self init];
    //[WMLog debug:"Loading in model found at " + modelPath];
    var m = require(modelPath);
    if (!m) {
        [WMLog error:"Cannot load model " + modelPath +
                     " - This is fatal unless it's the first " +
                     "time you're generating the model"];
        return nil;
    } else {
        //[WMLog debug:"Loaded data: " + m.toString()];
    }
    return [self initWithModelData:m.MODEL];
}

- (WMModel) initWithModelData:(id)modelData {
    [self init];
    model = modelData;

    /* by this point we have an empty model. */

    [self populateModel];

    /* Instantiate entity class descriptions for every entity type,
       which forces the class to cache each one
    */
    for (entityClass in model.ENTITIES) {
        [WMLog debug:"Caching entity class description for " + entityClass];
        var entityClassDescription = [self entityClassDescriptionForEntityNamed:entityClass];
    }
    [WMLog debug:"Loaded and populated model"];
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
        [WMLog debug:"Couldn't load ecd " + entityName];
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
