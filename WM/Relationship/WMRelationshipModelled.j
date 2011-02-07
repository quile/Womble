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
@import "../WMLog.j"

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
