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

@import "../WMObject.j"

@implementation WMEntityUniqueIdentifier : WMObject
{
    id entityName;
    id externalId;
    id entity;
}

+ (id) newFromString:(id)str {
    var e = [self new];
    var bits = [str componentsSeparatedByString:","];
    [e setEntityName:bits[0]];
    [e setExternalId:bits[1]];
    return e;
}

+ (id) newFromEntity:(id)entity {
    var e = [self new];
    [e setEntityName:[[entity entityClassDescription] name]];
    [e setExternalId:[entity externalId]];
    return e;
}

- (id) entityName {
    return entityName;
}

- (void) setEntityName:(id)value {
    entityName = value;
    entity = nil;
}

- externalId {
    return externalId;
}

- (void) setExternalId:(id)value {
    externalId = value;
    entity = nil;
}

- (CPString) description {
    return entityName + "," + externalId;
}

- entity {
    if (!entity) {
        entity = [[WMObjectContext new] entityWithUniqueIdentifier:self];
    }
    return entity;
}

@end
