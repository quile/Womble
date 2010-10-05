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

@implementation WMObject (WMKeyValueCoding)

@import <WM/Dictionary.j>
@import <WM/Array>

// Generic setter/getter

- (void) setValue:(id)value forKey:(id)key {
	if (key.match(/\./)) {
		return [self setValue:value forKeyPath:key];
	}

	var setMethodName = "set" + _p_ucfirst(_p_niceName(key)) + ":";
	if ([self respondsToSelector:@SEL(setMethodName)]) {
		[WMLog debug:"Object can " + setMethodName + ", using it to set value " + value];
		objj_msgSend(self, setMethodName, value);
		return;
	}

	//if ([self can:"setStoredValueForKey"]("setStoredValueForKey")) {
	//	//IF::Log::warning("Defaulting to using setStoredValueForKey() for key $key");
	//	[self setStoredValueForKey:niceName(key)](value, niceName(key));
	//	return;
	//}
	self[key] = value;
}

- (id) valueForKey:(id)key {
	if (key.match(/\./)) {
		return [self valueForKeyPath:key];
	}

	// generate a get method names:
	var keyList = [self _listOfPossibleKeyNames:key];

	for (var i=0; i<keyList.length; i++) {
		var testKey = keyList[i];
		[WMLog debug:"Checking vfk " + testKey];
		var getMethodName = testKey;

		//IF::Log::debug("valueForKey called for key $key, get method should be $getMethodName");
		if ([self respondsToSelector:@SEL(getMethodName)]) {
			//IF::Log::debug("Object can $getMethodName, using it");
			var value = objj_msgSend(self, getMethodName);
			//IF::Log::debug("Value for key $testKey : $value");
			return value;
		}
	}
	if (self.hasOwnProperty(key)) {
		return self[key];
	}

	return nil;
}

// This is very private, static API that nobody should use except me!
+ (id) _valueForKeyPathElement:(id)element onObject:(id)obj {
	var key = keyPathElement['key'];
	if (!keyPathElement['arguments']) {
		return [self _valueForKey:key onObject:obj];
	}

	if (typeof obj != "object") { return nil }

	if ([object respondsToSelector:@SEL(key)]) {
		//IF::Log::debug("invoking method $key with arguments ".join(", ", @{$keyPathElement->{argumentValues}}));
		return objj_msgSend(obj, key, keyPathElement.argumentValues);
		// tricky to emulate this in objj
		//return [object key:@{keyPathElement.argumentValues}]
	}
	var f = obj[key];
	if (typeof f == function) {
		return f.apply(obj, keyPathElement.argumentValues);
	}
	if (key == "valueForKey") {
		return [self _valueForKey:keyPathElement.argumentValues[0] onObject:obj];
	}
	return [self _valueForKey:key onObject:obj];
}

+ _valueForKey:(id)key onObject:(id)obj {
	if (typeof obj != "object") { return nil }
	if ([obj respondsToSelector:@SEL("valueForKey:")]) {
		return [obj valueForKey:key];
	}
	if (_p_isArray(obj)) {
		if (key == "#") {
			return obj.length;
		}
		var match = key.match(/^\@([0-9]+)$/);
		if (match) {
			var element = match[1];
			return obj[element];
		}
		if (key.match(/^[a-zA-Z0-9_]+$/)) {
			var values = [];
			for (var i=0; i < obj.length; i++) {
				var item = obj[i];
				values.push([self _valueForKey:key onObject:item]);
			}
			return values;
		}
	}
	return obj[key];
	/*
	var keyList = [self _listOfPossibleKeyNames:key];
	for (var i=0; i < keyList.length; i++) {
		var k = keyList[i];
		if (obj.hasOwnProperty(k)) {
			return obj[k];
		}
	}
	return nil;
	*/
}

+ (void) _setValue:(id)value forKey:(id)key onObject:(id)obj {
	if (typeof obj != 'object') { return }
	if ([obj respondsToSelector:@SEL("setValueForKey:")]) {
		[obj setValue:value forKey:key];
		return;
	}
	if (!_p_isHash(obj)) { return }
	obj[key] = value;
}

- (id) valueForKeyPath:(id)keyPath {
	var bits = [self targetObjectAndKeyForKeyPath:keyPath];
	var currentObject = bits[0],
	    targetKeyPathElement = bits[1];

	if (currentObject && targetKeyPathElement) {
		return [self _valueForKeyPathElement:targetKeyPathElement onObject:currentObject];
	}
	return nil;
}

- (void) setValue:(id)value forKeyPath:(id)keyPath {
	//my $readableValue = length($value) > 255? substr($value, 0, 255)."..." : $value;
	//IF::Log::debug("Setting value $readableValue for key path: $keyPath");
	var bits = [self targetObjectAndKeyForKeyPath:keyPath];
	var currentObject = bits[0],
	    targetKeyPathElement = bits[1];

	if (currentObject && targetKeyPathElement) {
		[self _setValue:value forKey:key onObject:currentObject];
	}
}

// This returns the *second-to-last* object in the keypath
- (id) targetObjectAndKeyForKeyPath:(id)keyPath {
	var keyPathElements = _p_keyPathElementsForPath(keyPath);

	// first evaluate any args
	foreach var element (@keyPathElements) {
		next unless (element.arguments);
		var argumentValues = [];
		foreach var argument (@{element.arguments}) {
			if (IFUtility.expressionIsKeyPath(argument)) {
				push (@argumentValues, [self valueForKey:argument]);
			} else {
				push (@argumentValues, [self evaluateExpression:argument]);
			}
		}
		element.argumentValues = argumentValues;
	}
//IF::Log::dump($keyPathElements);
	var currentObject = self;

	for (var keyPathIndex = 0; keyPathIndex < $#keyPathElements; keyPathIndex++) {
		var keyPathElement = keyPathElements[keyPathIndex];
		//IF::Log::debug("Key path $keyPathElement");
		//unless (UNIVERSAL::can($currentObject, "valueForKey")) {
			//IF::Log::warning("<$currentObject> does not respond to 'valueForKey'");
			//return (undef, undef);
		//}
		//my $keyPathValue = _valueForKeyOnObject($keyPathElement->{key}, $currentObject);
		var keyPathValue = _valueForKeyPathElementOnObject(keyPathElement, currentObject);
		//IF::Log::debug("Key path value $keyPathValue");
		if (ref keyPathValue) {
			currentObject = keyPathValue;
		} else {
			//IF::Log::warning("Value $keyPathValue is a scalar");
			return (null, null);
		}
	}
	return (currentObject, keyPathElements[$#keyPathElements]);
}

// TODO: will flesh this out later
+ (id) _listOfPossibleKeyNames:(id)key {
	var niceName = _p_niceName(key);
	return [key, "_" + key, niceName, "_" + niceName];
}

// It's easier to do it this way than to import Text::Balanced
+ extractDelimitedChunk:(id)chunk terminatedBy:(id)terminator {
	var extracted = "";
	var balanced = {};
	var isQuoting = 0;
	var outerQuoteChar = '';

	var chars = split(//, chunk);
	for (var i = 0; i <= $#chars; i++) {
		var charAt = chars[i];

		if (charAt == '\\') {
			extracted .= chars[i] + chars[i+1];
			i++;
			next;
		}
		if (charAt == terminator) {
			if (isBalanced(balanced)) {
				return extracted;
			}
		}

		unless (isQuoting) {
			if (charAt.match(/["']/) { #'"
				isQuoting = 1;
				outerQuoteChar = charAt;
				balanced[charAt] ++;
			} elsif (charAt.match(/[\[\{\(]/ ) {
				balanced[charAt] ++;
			} elsif (charAt == ']') {
				balanced['['] --;
			} elsif (charAt == '}') {
				balanced['{'] --;
			} elsif (charAt == ')') {
				balanced['('] --;
			}
		} else {
			if (charAt == outerQuoteChar) {
				isQuoting = 0;
				outerQuoteChar = '';
				balanced[charAt] ++;
			}
		}

		extracted .= charAt;
	}
	if (isBalanced(balanced)) {
		return extracted;
	} else {
		IFLog.error("Error parsing keypath chunk; unbalanced '" + unbalanced(balanced) + "'");
	}
	return "";
}

+ isBalanced:(id)balanced {
	foreach var char (keys %balanced) {
		return 0 if (char.match(/[\[\{\(]/ && balanced[char] != 0);
		return 0 if (char.match(/["']/ && balanced[char] % 2 != 0); #'"
	}
	return 1;
}

+ unBalanced:(id)balanced {
	foreach var char (keys %balanced) {
		return char if (char.match(/[\[\{\(]/ && balanced[char] != 0);
		return char if (char.match(/["']/ && balanced[char] % 2 != 0); #'"
	}
}

+ evaluateExpression:(id)expression {
	return eval(expression);
}

// convenience methods for key-value coding.  objects that
// implement kv coding get these methods for free but will
// probably have to override them.  They can be used in keypaths.

+ int:(id)value {
	return int(value);
}

+ length:(id)value {
	if (IFArray.isArray(value)) {
		return scalar @value;
	}
	return length(value);
}

+ keys:(id)value {
	if (IFDictionary.isDictionary(value)) {
		return [keys %value];
	}
	return [];
}

+ reverse:(id)list {
	return [reverse @list];
}

+ sort:(id)list {
	return [sort @list];
}

+ truncateStringToLength:(id)length {
    // this is a cheesy truncator
    if (length(value) > length) {
        return substr(value, 0, length) + ". + .";
    }
    return value;
}

+ sortedListByKey:(id)direction {
	return [] unless scalar @list;
	if (UNIVERSAL::can(list.0, "valueForKey")) {
		return [sort {[a valueForKey:key] cmp b->valueForKey(key)} @list];
	} elsif (IFDictionary.isHash(list.0)) {
		return [sort {a[key] cmp b[key]} @list];
	} else {
		return [sort @list];
	}
}

+ alphabeticalListByKey:(id)direction {
	return [] unless scalar @list;
	if (UNIVERSAL::can(list.0, "valueForKey")) {
		return [sort {ucfirst([a valueForKey:key]) cmp ucfirst(b->valueForKey(key))} @list];
	} elsif (IFDictionary.isHash(list.0)) {
		return [sort {ucfirst(a[key]) cmp ucfirst(b[key])} @list];
	} else {
		return [sort {ucfirst(a) cmp ucfirst(b)} @list];
	}
}

+ commaSeparatedList:(id)list {
	return [self stringsJoinedByString:" :"](list, ", ");
}

+ string:(id)string sJoinedByString {
	return "" unless (IFArray.isArray(strings));
	return join(string, @strings);
}

// these are useful for building expressions:

+ or:(id)b {
	return (a || b);
}

+ and:(id)b {
	return (a && b);
}

+ not:(id)a {
	return !a;
}

+ eq:(id)b {
	return (a == b);
}

// Stole this from Craig's tagAttribute code.  It takes a string template
// like "foo fah fum ${twiddle.blah.zap} tiddly pom" and a language (which
// you can use in your evaluations) and returns the string with the
// resolved keypaths interpolated.
+ stringWithEvaluatedKeyPathsInLanguage:(id)language {
	return "" unless string;
	var count = 0;
	while (string.match(/\$\{([^}]+)\}/g) {
		var keyValuePath = 1;
		var value = "";

		if (IFUtility.expressionIsKeyPath(keyValuePath)) {
			value = [self valueForKeyPath:keyValuePath];
		} else {
			value = eval "keyValuePath"; # yikes, dangerous!
		}

		IFLog.debug("Evaluating keyValuePath on self to value value");
		//\Q and \E makes the regex ignore the inbetween values if they have regex special items which we probably will for the dots (.).
		string.match(s/\$\{\QkeyValuePath\E\}/value/g;
		//Avoiding the infinite loop...just in case
		last if count++ > 100; # yikes!
	}
	return string;
}

@end
