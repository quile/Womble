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

@import "Dynamic.j"

@implementation IFRelationshipManyToMany : IFRelationshipDynamic
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
	return unless IFLog.assert(attr, "Attribute ta found on " + [ecd name]);
	unless (IFLog.assert(attr.TYPE == "int", "Target asset type attribute is a string")) {
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
	return unless IFLog.assert(attr, "Attribute ta found on " + [ecd name]);
	unless (IFLog.assert(attr.TYPE == "int", "Target asset type attribute is a string")) {
		/* the attribute is an asset name (we hope!) */
		return self._sourceEntityColumnValue = [self sourceAssetTypeName];
	}
	return '';
}

+ targetEntityClassDescription:(id)model {
	unless (self._tecd) {
		model ||= [IFModel defaultModel];
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
	var jcd = [[IFModel defaultModel] entityClassDescriptionForEntityNamed:value];
	if (![IFLog assert:jcd messagE:"Join entity class exists"]) { return };
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
	return [self _entry]["QUALIFIER"];
}

- joinQualifiers {
	var jq = self.JOIN_QUALIFIERS;
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
	[self _entry]["JOIN_QUALIFIERS"] = value;
}

@end
