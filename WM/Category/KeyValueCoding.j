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

@import <WM/Object.j>
@import <WM/Dictionary.j>
@import <WM/Array.j>
@import <WM/Helpers.js>
@import <WM/Utility.j>

__setValue_forKey = function(self, value, key) {
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

__valueForKey = function(self, key) {
	[WMLog debug:"Checking vfk " + key];
	if (key.match(/\./)) {
		return [self valueForKeyPath:key];
	}

	// generate a get method names:
	var keyList = [[self class] _listOfPossibleKeyNames:key];

	for (var i=0; i<keyList.length; i++) {
		var testKey = keyList[i];
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

__valueForKeyPathElement_onObject = function(self, keyPathElement, obj) {
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
	if (typeof f == "function") {
		return f.apply(obj, keyPathElement.argumentValues);
	}
	if (key == "valueForKey") {
		return [self _valueForKey:keyPathElement.argumentValues[0] onObject:obj];
	}
	return [self _valueForKey:key onObject:obj];
}

__valueForKey_onObject = function(self, key, obj) {
		if (typeof obj != "object") { return nil }
	if ([obj respondsToSelector:@SEL("valueForKey:")]) {
		return [obj valueForKey:key];
	}
	if (_p_isArray(obj)) {
		if (key == "#") {
			return obj.length;
		}
		var match = key.match(new RegExp("^\@([0-9]+)$"));
		if (match) {
			var element = match[1];
			return obj[element];
		}
		if (key.match(new RegExp("^[a-zA-Z0-9_]+$"))) {
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

__setValue_forKey_onObject = function(self, value, key, obj) {
	if (typeof obj != 'object') { return }
	if ([obj respondsToSelector:@SEL("setValueForKey:")]) {
		[obj setValue:value forKey:key];
		return;
	}
	if (!_p_isHash(obj)) { return }
	obj[key] = value;
}

__valueForKeyPath = function(self, keyPath) {
	var bits = [[self class] targetObjectAndKeyForKeyPath:keyPath];
	var currentObject = bits[0],
	    targetKeyPathElement = bits[1];

	if (currentObject && targetKeyPathElement) {
		return [self _valueForKeyPathElement:targetKeyPathElement onObject:currentObject];
	}
	return nil;
}

__setValue_forKeyPath = function(self, value, keyPath) {
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
__targetObjectAndKeyForKeyPath = function(self, keyPath) {
	var keyPathElements = objj_msgSend(WMUtility, "keyPathElementsForPath:", keyPath);
	// var keyPathElements = [WMUtility keyPathElementsForPath:keyPath];

	// first evaluate any args
	for (var i=0; i<keyPathElements.length; i++) {
		var element = keyPathElements[i];
		if (!element['arguments']) { continue }
		var argumentValues = [];
		for (var j=0; j<element['arguments'].length; j++) {
			var argument = element['arguments'][j];
			if ([WMUtility expressionIsKeyPath:argument]) {
				argumentValues.push([self valueForKey:argument]);
			} else {
				argumentValues.push([self evaluateExpression:argument]);
			}
		}
		element.argumentValues = argumentValues;
	}
//IF::Log::dump($keyPathElements);
	var currentObject = self;

	for (var keyPathIndex = 0; keyPathIndex < (keyPathElements.length - 1); keyPathIndex++) {
		var keyPathElement = keyPathElements[keyPathIndex];
		//IF::Log::debug("Key path $keyPathElement");
		//unless (UNIVERSAL::can($currentObject, "valueForKey")) {
			//IF::Log::warning("<$currentObject> does not respond to 'valueForKey'");
			//return (undef, undef);
		//}
		//my $keyPathValue = _valueForKeyOnObject($keyPathElement->{key}, $currentObject);
		var keyPathValue = [self _valueForKeyPathElement:keyPathElement onObject:currentObject];
		//IF::Log::debug("Key path value $keyPathValue");
		if (typeof keyPathValue == "object") {
			currentObject = keyPathValue;
		} else {
			//IF::Log::warning("Value $keyPathValue is a scalar");
			return [nil, nil];
		}
	}
	return [currentObject, keyPathElements[keyPathElements.length-1]];
}

// TODO: will flesh this out later
__listOfPossibleKeyNames = function(self, key) {
	var niceName = _p_niceName(key);
	return [key, "_" + key, niceName, "_" + niceName];
}

__evaluateExpression = function(self, expression) {
	return eval(expression);
}

// convenience methods for key-value coding.  objects that
// implement kv coding get these methods for free but will
// probably have to override them.  They can be used in keypaths.

__int = function(self, value) {
	return value;
}

__length = function(self, value) {
	if (_p_isArray(value)) {
		return value.length;
	}
	return value.length;
}

__keys = function(self, value) {
	if (typeof value == "object") {
		return value.keys();
	}
	return [];
}

__reverse = function(self, list) {
	return list.reverse();
}

__sort = function(self, list) {
	return list.sort();
}

__truncateStringToLength = function(self, length) {
    // this is a cheesy truncator
    if (value.length > length) {
        return value.substring(0, length) + "...";
    }
    return value;
}

/*
+ sortedListByKey:(id)direction {
	if (!list.length) { return [] }
	if ([list[0] respondsToSelector:@SEL("valueForKey")]) {
		return [sort {[a valueForKey:key] cmp b->valueForKey(key)} @list];
	} elsif (IFDictionary.isHash(list.0)) {
		return [sort {a[key] cmp b[key]} @list];
	} else {
		return [sort @list];
	}
}
*/

/*
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
*/

__commaSeparatedList = function(self, list) {
	return [list componentsJoinedByString:", "];
}

// these are useful for building expressions:

__or = function(self, a, b) {
	return (a || b);
}

__and = function(self, a, b) {
	return (a && b);
}

__not = function(self, a) {
	return !a;
}

__eq = function(self, a, b) {
	return (a == b);
}

// Stole this from Craig's tagAttribute code.  It takes a string template
// like "foo fah fum ${twiddle.blah.zap} tiddly pom" and a language (which
// you can use in your evaluations) and returns the string with the
// resolved keypaths interpolated.
__string_withEvaluatedKeyPathsInLanguage = function(self, str, language) {
	if (!str) { return "" }
	var count = 0;
	var TEMPLATE_RE = new RegExp("\$\{([^}]+)\}", "g");
	var match = str.match(TEMPLATE_RE);
	while (match) {
		var keyValuePath = match[1];
		var value = "";

		if ([WMUtility expressionIsKeyPath:keyValuePath]) {
			value = [self valueForKeyPath:keyValuePath];
		} else {
			value = eval(keyValuePath); // yikes, dangerous!
		}

		[WMLog debug:"Evaluating " + keyValuePath + " on self to value " + value];
		//\Q and \E makes the regex ignore the inbetween values if they have regex special items which we probably will for the dots (.).
		var re = new RegExp("\$\{" + _p_quotemeta(keyValuePath) + "\}", "g");
		str = str.replace(re, value);
		//Avoiding the infinite loop...just in case
		if (count++ > 100) { break }
		match = str.match(TEMPLATE_RE);
	}
	return str;
}


/*-----------------------------------------------------*/

@implementation WMObject (WMKeyValueCoding)

+ (id) _valueForKeyPathElement:(id)element onObject:(id)obj { return __valueForKey_onObject(self, element, obj); }
+ (id) _valueForKey:(id)key onObject:(id)obj { return __valueForKey_onObject(self, key, obj); }
+ (void) _setValue:(id)value forKey:(id)key onObject:(id)obj { return __setValue_forKey_onObject(self, value, key, obj); }
+ (id) targetObjectAndKeyForKeyPath:(id)keyPath { return __targetObjectAndKeyForKeyPath(self, keyPath); }
+ (id) _listOfPossibleKeyNames:(id)key { return __listOfPossibleKeyNames(self, key); }
+ (id) evaluateExpression:(id)expression { 	return __evaluateExpression(self, expression); }

- (void) setValue:(id)value forKey:(id)key { return __setValue_forKey(self, value, key); }
- (id) valueForKey:(id)key { return __valueForKey(self, key); }
- (id) valueForKeyPath:(id)keyPath { return __valueForKeyPath(self, keyPath); }
- (void) setValue:(id)value forKeyPath:(id)keyPath { return __setValue_forKeyPath(self, value, keyPath); }
- (id) int:(id)value { return __int(self, value); }
- (id) length:(id)value { return __length(self, value); }
- (id) keys:(id)value { return __keys(self, value); }
- (id) reverse:(id)list { return __reverse(self, list); }
- (id) sort:(id)list { return __sort(self, list); }
- (id) truncateString:(id)str toLength:(id)length { return __truncateString_toLength(self, string, length); }
- (id) commaSeparatedList:(id)list { return __commaSeparatedList(self, list); }
- (id) or:(id)a :(id)b { return __or(self, a, b); }
- (id) and:(id)a :(id)b { return __and(self, a, b); }
- (id) not:(id)a { return __not(self, a); }
- (id) eq:(id)a :(id)b { return __eq(self, a, b); }
+ (id) string:(id)str withEvaluatedKeyPathsInLanguage:(id)language { return __string_withEvaluateKeyPathsInLanguage(self, str, language); }

@end


@implementation CPDictionary (WMKeyValueCoding)

+ (id) _valueForKeyPathElement:(id)element onObject:(id)obj { return __valueForKey_onObject(self, element, obj); }
+ (id) _valueForKey:(id)key onObject:(id)obj { return __valueForKey_onObject(self, key, obj); }
+ (void) _setValue:(id)value forKey:(id)key onObject:(id)obj { return __setValue_forKey_onObject(self, value, key, obj); }
+ (id) targetObjectAndKeyForKeyPath:(id)keyPath { return __targetObjectAndKeyForKeyPath(self, keyPath); }
+ (id) _listOfPossibleKeyNames:(id)key { return __listOfPossibleKeyNames(self, key); }
+ (id) evaluateExpression:(id)expression { 	return __evaluateExpression(self, expression); }

- (void) setValue:(id)value forKey:(id)key { return __setValue_forKey(self, value, key); }
- (id) valueForKey:(id)key { return __valueForKey(self, key); }
- (id) valueForKeyPath:(id)keyPath { return __valueForKeyPath(self, keyPath); }
- (void) setValue:(id)value forKeyPath:(id)keyPath { return __setValue_forKeyPath(self, value, keyPath); }
- (id) int:(id)value { return __int(self, value); }
- (id) length:(id)value { return __length(self, value); }
- (id) keys:(id)value { return __keys(self, value); }
- (id) reverse:(id)list { return __reverse(self, list); }
- (id) sort:(id)list { return __sort(self, list); }
- (id) truncateString:(id)str toLength:(id)length { return __truncateString_toLength(self, string, length); }
- (id) commaSeparatedList:(id)list { return __commaSeparatedList(self, list); }
- (id) or:(id)a :(id)b { return __or(self, a, b); }
- (id) and:(id)a :(id)b { return __and(self, a, b); }
- (id) not:(id)a { return __not(self, a); }
- (id) eq:(id)a :(id)b { return __eq(self, a, b); }
+ (id) string:(id)str withEvaluatedKeyPathsInLanguage:(id)language { return __string_withEvaluateKeyPathsInLanguage(self, str, language); }

@end


@implementation WMArray (WMKeyValueCoding)

+ (id) _valueForKeyPathElement:(id)element onObject:(id)obj { return __valueForKey_onObject(self, element, obj); }
+ (id) _valueForKey:(id)key onObject:(id)obj { return __valueForKey_onObject(self, key, obj); }
+ (void) _setValue:(id)value forKey:(id)key onObject:(id)obj { return __setValue_forKey_onObject(self, value, key, obj); }
+ (id) targetObjectAndKeyForKeyPath:(id)keyPath { return __targetObjectAndKeyForKeyPath(self, keyPath); }
+ (id) _listOfPossibleKeyNames:(id)key { return __listOfPossibleKeyNames(self, key); }
+ (id) evaluateExpression:(id)expression { 	return __evaluateExpression(self, expression); }

- (void) setValue:(id)value forKey:(id)key { return __setValue_forKey(self, value, key); }
- (id) valueForKey:(id)key { return __valueForKey(self, key); }
- (id) valueForKeyPath:(id)keyPath { return __valueForKeyPath(self, keyPath); }
- (void) setValue:(id)value forKeyPath:(id)keyPath { return __setValue_forKeyPath(self, value, keyPath); }
- (id) int:(id)value { return __int(self, value); }
- (id) length:(id)value { return __length(self, value); }
- (id) keys:(id)value { return __keys(self, value); }
- (id) reverse:(id)list { return __reverse(self, list); }
- (id) sort:(id)list { return __sort(self, list); }
- (id) truncateString:(id)str toLength:(id)length { return __truncateString_toLength(self, string, length); }
- (id) commaSeparatedList:(id)list { return __commaSeparatedList(self, list); }
- (id) or:(id)a :(id)b { return __or(self, a, b); }
- (id) and:(id)a :(id)b { return __and(self, a, b); }
- (id) not:(id)a { return __not(self, a); }
- (id) eq:(id)a :(id)b { return __eq(self, a, b); }
+ (id) string:(id)str withEvaluatedKeyPathsInLanguage:(id)language { return __string_withEvaluateKeyPathsInLanguage(self, str, language); }

@end
