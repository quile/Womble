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

@import "Modelled.j"

/* A dynamic relationship is one that is not
   modelled in the pmodel file, that needs to
   be created at runtime, based on derived info
   usually from a column in a table.
*/

@implementation IFRelationshipDynamic : IFRelationshipModelled
{
    /* The name is what should be used in key paths in qualifiers */
    id name @accessors;
    id sourceAttributeName @accessors;
    id targetAttributeName @accessors;
    id sourceAttribute;
    id targetAttribute;
    id targetAssetTypeAttribute @accessors;
    id _targetEntityColumnValue;
    id _sourceEntityColumnValue;
    id _tecd;
    /* This gets set when the dynamic relationship is added the fetchspec */
    id entityClassDescription @accessors;
    /* This is the name */
    id targetAssetTypeName @accessors;
}

- sourceAttribute {
    sourceAttribute = sourceAttribute || [[self entityClassDescription] columnNameForAttributeName:sourceAttributeName];
    return sourceAttribute;
}

- setSourceAttribute:(id)value {
	sourceAttribute = value;
}

- targetAttribute {
    targetAttribute = targetAttribute || [[self targetEntityClassDescription] columnNameForAttributeName:targetAttributeName];
}

- setTargetAttribute:(id)value {
	targetAttribute = value;
}

/* this is here for compatibility only */
- targetEntity {
	return [self targetAssetTypeName];
}

/*---------------------------------- */

- targetEntityColumnValue {
    if (_targetEntityColumnValue) { return _targetEntityColumnValue }

	var ta = [self targetAssetTypeAttribute];
    if (!ta) { return '' }
	/* how do we get the attribute information?  hmmmm */
	var ecd = [self entityClassDescription];
	var attr = [ecd attributeWithName:ta];
    if (![IFLog assert:attr message:"Attribute " + ta + " found on " + [ecd name]]) { return '' };
	if (![IFLog assert:attr['TYPE'] == "int" message:"Target asset type attribute is a string"]) {
		/* the attribute is an asset name (we hope!) */
		_targetEntityColumnValue = [self targetAssetTypeName];
        return _targetEntityColumnValue;
	}
	return '';
}

- targetEntityClassDescription:(id)model {
    if (!_tecd) {
		var model = model || [IFModel defaultModel];
		_tecd = [model entityClassDescriptionForEntityNamed:[self targetAssetTypeName]];
	}
	return _tecd;
}

/* what should this be? */
- type {
	return "TO_MANY";
}

- qualifier {
	if ([self targetAssetTypeAttribute]) {
		/* we need to qualify the source table on this, because it
		   stores the name or asset-type-id of the target asset type
		   (and therefore the target table) in the source table
        */
		var columnValue = [self targetEntityColumnValue];
		if ([IFLog assert:columnValue message:"Target asset type column value exists"]) {
			var q = [IFQualifier key:[self targetAssetTypeAttribute] + " = %@", columnValue];
			[q setEntity:[[self entityClassDescription] name]];
			return q;
		}
	}
	return [self _entry]['QUALIFIER'];
}

@end
