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


@import "Log.j"
//@import "Qualifier.j"

// what do we do with these?
//			 'ne': "ne",
//			 'eq': "eq";

@implementation IFPrimaryKey : IFObject
{
    id _keyDefinition @accessors;
    id _keyFields @accessors;
    id _keyFieldNames;
}

- init {
    [super init];
    _keyFields = {};
    _keyFieldNames = [];
    _keyDefinition = nil;
    return self;
}

- initWithKeyDefinition:(id)kd {
    [self init];
	[self _setKeyDefinition:kd];
	return self;
}

- _keyDefinition {
	return _keyDefinition;
}

- _setKeyDefinition:(id)value {
	_keyDefinition = value;
	[self setKeyFieldsFromKeyDefinition:_keyDefinition];
}

- setKeyFieldsFromKeyDefinition:(id)kd {
	var keys = kd.split(":");
	_keyFieldNames = keys;
    var order = 0;
	for (i=0; i<keys.length; i++) {
        var key = keys[i]
		_keyFields[key] = {
			key: key,
			order: order
		};
		order++;
	}
}

- hasKey:(id)key {
	return (_keyFields[key] != null);
}

- keyFields {
	return _keyFieldNames;
}

- qualifierForValue:(id)value {
	if ([self isCompound]) {
		// expect a number of values
		return [self qualifierForValues:value.split(":")];
	}
	return [self qualifierForValues:[value]];
}

- qualifierForValues:(id)values {
	var qualifiers = [];
	for (var key in _keyFields) {
		qualifiers[qualifiers.length] = [IFKeyValueQualifier key:key + " = %@", values[_keyFields[key]['order']]];
	}
	if (qualifiers.length == 1) {
		return qualifiers[0];
	}
    return [IFQualifier and:qualifiers];
}

- valueForEntity:(id)entity {
    var values = [self valuesForEntity:entity];
	return values.join(":");
}

- valuesForEntity:(id)entity {
	var values = [];
    [IFLog dump:_keyFields];
	for (var key in _keyFields) {
        values[values.length] = [entity storedValueForRawKey:key];
        //[IFLog debug:"PK value " + values[values.length - 1] + " for key " + key];
	}
	return values;
}

- setValue:(id)value forEntity:(id)entity {
	var values = value.split(":");
	for (var i=0; i<values.length; i++) {
		[entity setStoredValue:values[i] forRawKey:key];
	}
}

- asString {
	return _keyDefinition;
}

- isCompound {
	return _p_keys(_keyFields).length > 1;
}

- description {
    return [self asString] + "";
}

/*
+ ne:(id)other {
	return ([self stringValue] != other);
}

+ eq:(id)other {
	return ([self stringValue] == other);
}
*/

@end
