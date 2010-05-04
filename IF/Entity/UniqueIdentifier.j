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

@import "../Object.j"

@implementation IFEntityUniqueIdentifier : IFObject
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
        entity = [[IFObjectContext new] entityWithUniqueIdentifier:self];
    }
    return entity;
}

@end
