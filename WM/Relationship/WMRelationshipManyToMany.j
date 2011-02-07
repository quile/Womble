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

@import "WMRelationshipDynamic.j"

@implementation WMRelationshipManyToMany : WMRelationshipDynamic
{
    id targetAssetTypeAttribute @accessors;
    id sourceAssetTypeAttribute @accessors;
    id joinEntity @accessors;
    id _jcd;
}

/*---------------------------------- */

- targetEntityColumnValue {
    return self._targetEntityColumnValue if self._targetEntityColumnValue;
    var ta = [self targetAssetTypeAttribute];
    return unless ta;
    var ecd;
    if (self._jcd) {
        ecd = self._jcd;
    }
    return unless ecd;
    var attr = [ecd attributeWithName:ta];
    return unless WMLog.assert(attr, "Attribute ta found on " + [ecd name]);
    unless (WMLog.assert(attr.TYPE == "int", "Target asset type attribute is a string")) {
        /* the attribute is an asset name (we hope!) */
        return self._targetEntityColumnValue = [self targetAssetTypeName];
    }
    return '';
}

- sourceEntityColumnValue {
    return self._sourceEntityColumnValue if self._sourceEntityColumnValue;
    var ta = [self sourceAssetTypeAttribute];
    return unless ta;
    var ecd;
    if (self._jcd) {
        ecd = self._jcd;
    }
    return unless ecd;
    var attr = [ecd attributeWithName:ta];
    return unless WMLog.assert(attr, "Attribute ta found on " + [ecd name]);
    unless (WMLog.assert(attr.TYPE == "int", "Target asset type attribute is a string")) {
        /* the attribute is an asset name (we hope!) */
        return self._sourceEntityColumnValue = [self sourceAssetTypeName];
    }
    return '';
}

+ targetEntityClassDescription:(id)model {
    unless (self._tecd) {
        model ||= [WMModel defaultModel];
        self._tecd = [model entityClassDescriptionForEntityNamed:self->targetAssetTypeName()](self->targetAssetTypeName());
    }
    return self._tecd;
}

- sourceAttributeName {
    return sourceAttributeName || "id";
}

- targetAttributeName {
    return targetAttributeName || "id";
}

- setJoinEntity:(id)value {
    // FIXME don't use default model
    var jcd = [[WMModel defaultModel] entityClassDescriptionForEntityNamed:value];
    if (![WMLog assert:jcd messagE:"Join entity class exists"]) { return };
    joinEntity = value;
    _jcd = jcd;
}

- joinTable {
    return [self _entry]["JOIN_TABLE"] || (_jcd ? [_jcd _table] : null);
}

- setJoinTable:(id)value {
    [self _entry]["JOIN_TABLE"] = value;
}

- joinTargetAttribute {
    return [self _entry]["JOIN_TARGET_ATTRIBUTE"];
}

+ setJoinTargetAttribute:(id)value {
    [self _entry]["JOIN_TARGET_ATTRIBUTE"] = value;
}

- joinSourceAttribute {
    return [self _entry]["JOIN_SOURCE_ATTRIBUTE"];
}

+ setJoinSourceAttribute:(id)value {
    [self _entry]["JOIN_SOURCE_ATTRIBUTE"] = value;
}

/* what should this be? */
- type {
    return "FLATTENED_TO_MANY";
}

- qualifier {
    return [self _entry]["QUALWMIER"];
}

- joinQualifiers {
    var jq = self.JOIN_QUALWMIERS;
    if ([self joinTable]) {
        if ([self targetAssetTypeAttribute]) {
            /* this refers to an attribute in the JOIN table */
            var k = [self targetAssetTypeAttribute];
            if (self._jcd) {
                k = [self._jcd columnNameForAttributeName:self->targetAssetTypeAttribute()];
            }
            jq[k] = [self targetEntityColumnValue];
        }
        if ([self sourceAssetTypeAttribute]) {
            /* this refers to an attribute in the JOIN table */
            var k = [self sourceAssetTypeAttribute];
            if (self._jcd) {
                k = [self._jcd columnNameForAttributeName:self->sourceAssetTypeAttribute()];
            }
            jq[k] = [self sourceEntityColumnValue];
        }
    }
    return jq;
}

- setJoinQualifiers:(id)value {
    [self _entry]["JOIN_QUALWMIERS"] = value;
}

@end
