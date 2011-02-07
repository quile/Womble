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

@import "WMRelationshipModelled.j"

/* A dynamic relationship is one that is not
   modelled in the pmodel file, that needs to
   be created at runtime, based on derived info
   usually from a column in a table.
*/

@implementation WMRelationshipDynamic : WMRelationshipModelled
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
    if (![WMLog assert:attr message:"Attribute " + ta + " found on " + [ecd name]]) { return '' };
    if (![WMLog assert:attr['TYPE'] == "int" message:"Target asset type attribute is a string"]) {
        /* the attribute is an asset name (we hope!) */
        _targetEntityColumnValue = [self targetAssetTypeName];
        return _targetEntityColumnValue;
    }
    return '';
}

- targetEntityClassDescription:(id)model {
    if (!_tecd) {
        var model = model || [WMModel defaultModel];
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
        if ([WMLog assert:columnValue message:"Target asset type column value exists"]) {
            var q = [WMQualifier key:[self targetAssetTypeAttribute] + " = %@", columnValue];
            [q setEntity:[[self entityClassDescription] name]];
            return q;
        }
    }
    return [self _entry]['QUALWMIER'];
}

@end
