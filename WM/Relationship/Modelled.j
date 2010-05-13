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

@import "../Object.j"
@import "../Log.j"

@implementation WMRelationshipModelled : WMObject
{
    id _entry @accessors;
    WMEntityClassDescription _tecd;
}

/* This represents an entry in the RELATIONSHIPS hash for a given
   entity in the model
*/

var TYPES = {
    TO_ONE: 1,
    TO_MANY: 2,
    FLATTENED_TO_MANY: 3,
};

+ newFromModelEntry:(id)entry withName:(id)n {
    if (!entry) { return nil }
    var r = [[self alloc] init];
    r._name = n;
    [r _setEntry:entry];
    return r;
}

- targetEntity {
    return [self _entry]['TARGET_ENTITY'];
}

- targetEntityClassDescription:(id)model {
    if (!_tecd) {
        model = model || [WMModel defaultModel];
        _tecd = [model entityClassDescriptionForEntityNamed:[self targetEntity]];
    }
    return _tecd;
}

- sourceAttribute {
    return [self _entry]['SOURCE_ATTRIBUTE'];
}

- targetAttribute {
    return [self _entry]['TARGET_ATTRIBUTE'];
}

- joinTable {
    return [self _entry]['JOIN_TABLE'];
}

- joinTargetAttribute {
    return [self _entry]['JOIN_TARGET_ATTRIBUTE'];
}

- joinSourceAttribute {
    return [self _entry]['JOIN_SOURCE_ATTRIBUTE'];
}

- type {
    return [self _entry]['TYPE'];
}

- qualifier {
    return [self _entry]['QUALWMIER'];
}

- joinQualifiers {
    return [self _entry]['JOIN_QUALWMIERS'];
}

- defaultSortOrderings {
    return [self _entry]['DEFAULT_SORT_ORDERINGS'];
}

- isToOne {
    return [self type] == 'TO_ONE';
}

- isReadOnly {
    return [self _entry]['IS_READ_ONLY'];
}

- hints {
    return [self _entry]['RELATIONSHIP_HINTS'];
}

- deletionRule {
    return [self _entry]['DELETION_RULE'];
}

- reciprocalRelationshipName {
    return [self _entry]['RECIPROCAL_RELATIONSHIP_NAME'];
}

- name {
    return self._name;
}

@end
