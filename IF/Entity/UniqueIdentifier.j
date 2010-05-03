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

@implementation IFEntityUniqueIdentifier : IFDictionary {

@import <strict>;
use base qw(
    IFDictionary
);
/* use overload '""' => 'stringValue'; */


+ new {
    var self = className->SUPER::new();
    bless self, className;
}

+ newFromString:(id)string {
    var self = [className new];
    var (e, p) = split(/\,/, string, 2);
    [self setEntityName:e];
    [self setExternalId:p];
    return self;
}

+ newFromEntity:(id)entity {
    var self = [className new];
    [self setEntityName:entity->entityClassDescription()->name()];
    [self setExternalId:entity->externalId()];
    return self;
}

- entityName {
    return self.entityName;
}

+ setEntityName:(id)value {
    self.entityName = value;
    self.entity = null;
}

- externalId {
    return self.externalId;
}

+ setExternalId:(id)value {
    self.externalId = value;
    self.entity = null;
}

- stringValue {
    return [self entityName] + "," + self->externalId();
}

- entity {
    return self.entity ||= [IFObjectContext new]->entityWithUniqueIdentifier(self);
}

@end