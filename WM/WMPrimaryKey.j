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


@import "WMLog.j"
//@import "Qualifier.j"

// what do we do with these?
//             'ne': "ne",
//             'eq': "eq";

@implementation WMPrimaryKey : WMObject
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
        qualifiers[qualifiers.length] = [WMKeyValueQualifier key:key + " = %@", values[_keyFields[key]['order']]];
    }
    if (qualifiers.length == 1) {
        return qualifiers[0];
    }
    return [WMQualifier and:qualifiers];
}

- valueForEntity:(id)entity {
    var values = [self valuesForEntity:entity];
    return values.join(":");
}

- valuesForEntity:(id)entity {
    var values = [];
    [WMLog dump:_keyFields];
    for (var key in _keyFields) {
        values[values.length] = [entity storedValueForRawKey:key];
        //[WMLog debug:"PK value " + values[values.length - 1] + " for key " + key];
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
