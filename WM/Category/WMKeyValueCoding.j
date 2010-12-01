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

@import <WM/WMObject.j>
@import <WM/WMDictionary.j>
@import <WM/WMArray.j>
@import <WM/Helpers.js>
@import <WM/WMUtility.j>
@import <WM/WMLog.j>

__setValue_forKey = function(self, v, key) {
	if (key.match(/\./)) {
		return [self setValue:v forKeyPath:key];
	}

	var setMethodName = "set" + _p_ucfirst(_p_niceName(key)) + ":";
	if ([self respondsToSelector:@SEL(setMethodName)]) {
		//[WMLog debug:"Object can " + setMethodName + ", using it to set value " + value];
		objj_msgSend(self, setMethodName, v);
		return;
	}

	if ([self respondsToSelector:@SEL("setObject:forKey:")]) {
		return [self setObject:v forKey:key];
	}
	//if ([self can:"setStoredValueForKey"]("setStoredValueForKey")) {
	//	//IF::Log::warning("Defaulting to using setStoredValueForKey() for key $key");
	//	[self setStoredValueForKey:niceName(key)](value, niceName(key));
	//	return;
	//}
	self[key] = v;
}

var DOT_OR_PARENTHESIS = new RegExp("[\.\(]");

__valueForKey = function(self, key) {
	//[WMLog debug:"Checking vfk " + key];
	if (key.match(DOT_OR_PARENTHESIS)) {
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
			var v = objj_msgSend(self, getMethodName);
			//IF::Log::debug("Value for key $testKey : $value");
			return v;
		}
	}
	if ([self respondsToSelector:@SEL("objectForKey:")]) {
		return [self objectForKey:key];
	}
	if (self.hasOwnProperty(key)) {
		return self[key];
	}

	return nil;
}

__valueForKeyPathElement_onObject = function(self, keyPathElement, obj) {
	//[WMLog debug:"Looking for " + keyPathElement.toSource() + " on object " + obj];
	var key = keyPathElement['key'];
	if (!keyPathElement['arguments']) {
		return __valueForKey_onObject(self, key, obj);
		//return [self _valueForKey:key onObject:obj];
	}

	if (typeof obj != "object") { return nil }

	var sel = key;
	for (var i=0; i<keyPathElement['argumentValues'].length; i++) {
		sel = sel + ":";
	}
	if (obj.isa && [obj respondsToSelector:@SEL(sel)]) {
		//IF::Log::debug("invoking method $key with arguments ".join(", ", @{$keyPathElement->{argumentValues}}));
		//[WMLog debug:"invoking method " + sel + " with arguments " + keyPathElement.argumentValues.toSource()];
		return objj_msgSend.apply(nil, [obj, sel].concat(keyPathElement.argumentValues));
		// tricky to emulate this in objj
		//return [object key:@{keyPathElement.argumentValues}]
	}
	var f = obj[key];
	if (typeof f == "function") {
		return f.apply(obj, keyPathElement.argumentValues);
	}
	if (key == "valueForKey") {
		return __valueForKey_onObject(self, keyPathElement.argumentValues[0], obj);
		//return [self _valueForKey:keyPathElement.argumentValues[0] onObject:obj];
	}
	return [self _valueForKey:key onObject:obj];
}

__valueForKey_onObject = function(self, key, obj) {
	if (typeof obj != "object") { return nil }
	if (_p_isArray(obj)) {
		if (key == "#") {
			return obj.length;
		}
		//[WMLog debug:"array key is " + key];
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
	if (obj.isa && [obj respondsToSelector:@SEL("valueForKey:")]) {
		//[WMLog debug:"... responds to valueForKey:, calling it now."]
		return __valueForKey(obj, key);
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

__setValue_forKey_onObject = function(self, v, key, obj) {
	if (typeof obj != 'object') { return }
	if ([obj respondsToSelector:@SEL("setValueForKey:")]) {
		return __setValue_forKey(obj, v, key);
		//return [obj setValue:value forKey:key];
	}
	if (!_p_isHash(obj)) { return }
	obj[key] = v;
}

__valueForKeyPath = function(self, keyPath) {
	var bits = __targetObjectAndKeyForKeyPath(self, keyPath);
	var currentObject = bits[0],
	    targetKeyPathElement = bits[1];

	if (currentObject && targetKeyPathElement) {
		return [[self class] _valueForKeyPathElement:targetKeyPathElement onObject:currentObject];
	}
	return nil;
}

__setValue_forKeyPath = function(self, v, keyPath) {
	//my $readableValue = length($value) > 255? substr($value, 0, 255)."..." : $value;
	//IF::Log::debug("Setting value $readableValue for key path: $keyPath");
	var bits = [self targetObjectAndKeyForKeyPath:keyPath];
	var currentObject = bits[0],
	    targetKeyPathElement = bits[1];

	if (currentObject && targetKeyPathElement) {
		[self _setValue:v forKey:key onObject:currentObject];
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
	var currentObject = self;

	for (var keyPathIndex = 0; keyPathIndex < (keyPathElements.length - 1); keyPathIndex++) {
		var keyPathElement = keyPathElements[keyPathIndex];
		//IF::Log::debug("Key path $keyPathElement");
		//unless (UNIVERSAL::can($currentObject, "valueForKey")) {
			//IF::Log::warning("<$currentObject> does not respond to 'valueForKey'");
			//return (undef, undef);
		//}
		//my $keyPathValue = _valueForKeyOnObject($keyPathElement->{key}, $currentObject);
		var keyPathValue = [[self class] _valueForKeyPathElement:keyPathElement onObject:currentObject];
		//IF::Log::debug("Key path value $keyPathValue");
		if (typeof keyPathValue == "object") {
			currentObject = keyPathValue;
		} else {
			//IF::Log::warning("Value $keyPathValue is a scalar");
			return [nil, nil];
		}
	}
	//[WMLog debug:"returning " + currentObject + " / " + keyPathElements[keyPathElements.length-1].toSource()];
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

__int = function(self, v) {
	return v;
}

__length = function(self, v) {
	if (_p_isArray(v)) {
		return v.length;
	}
	return v.length;
}

__keys = function(self, v) {
	if (typeof v == "object") {
		return v.keys();
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
    if (v.length > length) {
        return v.substring(0, length) + "...";
    }
    return v;
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
		var v = "";

		if ([WMUtility expressionIsKeyPath:keyValuePath]) {
			v = [[self class] valueForKeyPath:keyValuePath];
		} else {
			v = eval(keyValuePath); // yikes, dangerous!
		}

		//[WMLog debug:"Evaluating " + keyValuePath + " on self to value " + value];
		//\Q and \E makes the regex ignore the inbetween values if they have regex special items which we probably will for the dots (.).
		var re = new RegExp("\$\{" + _p_quotemeta(keyValuePath) + "\}", "g");
		str = str.replace(re, v);
		//Avoiding the infinite loop...just in case
		if (count++ > 100) { break }
		match = str.match(TEMPLATE_RE);
	}
	return str;
}


/*-----------------------------------------------------*/

@implementation WMObject (WMKeyValueCoding)

+ (id) _valueForKeyPathElement:(id)element onObject:(id)obj { return __valueForKeyPathElement_onObject(self, element, obj); }
+ (id) _valueForKey:(id)key onObject:(id)obj { return __valueForKey_onObject(self, key, obj); }
+ (void) _setValue:(id)v forKey:(id)key onObject:(id)obj { return __setValue_forKey_onObject(self, v, key, obj); }
+ (id) _listOfPossibleKeyNames:(id)key { return __listOfPossibleKeyNames(self, key); }

- (id) evaluateExpression:(id)expression { 	return __evaluateExpression(self, expression); }
- (id) targetObjectAndKeyForKeyPath:(id)keyPath { return __targetObjectAndKeyForKeyPath(self, keyPath); }
- (void) setValue:(id)v forKey:(id)key { return __setValue_forKey(self, v, key); }
- (id) valueForKey:(id)key { return __valueForKey(self, key); }
- (id) valueForKeyPath:(id)keyPath { return __valueForKeyPath(self, keyPath); }
- (void) setValue:(id)v forKeyPath:(id)keyPath { return __setValue_forKeyPath(self, v, keyPath); }
- (id) int:(id)v { return __int(self, v); }
- (id) length:(id)v { return __length(self, v); }
- (id) keys:(id)v { return __keys(self, v); }
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

+ (id) _valueForKeyPathElement:(id)element onObject:(id)obj { return __valueForKeyPathElement_onObject(self, element, obj); }
+ (id) _valueForKey:(id)key onObject:(id)obj { return __valueForKey_onObject(self, key, obj); }
+ (void) _setValue:(id)v forKey:(id)key onObject:(id)obj { return __setValue_forKey_onObject(self, v, key, obj); }
+ (id) _listOfPossibleKeyNames:(id)key { return __listOfPossibleKeyNames(self, key); }

- (id) evaluateExpression:(id)expression { 	return __evaluateExpression(self, expression); }
- (id) targetObjectAndKeyForKeyPath:(id)keyPath { return __targetObjectAndKeyForKeyPath(self, keyPath); }
- (void) setValue:(id)v forKey:(id)key { return __setValue_forKey(self, v, key); }
- (id) valueForKey:(id)key { return __valueForKey(self, key); }
- (id) valueForKeyPath:(id)keyPath { return __valueForKeyPath(self, keyPath); }
- (void) setValue:(id)v forKeyPath:(id)keyPath { return __setValue_forKeyPath(self, v, keyPath); }
- (id) int:(id)v { return __int(self, v); }
- (id) length:(id)v { return __length(self, v); }
- (id) keys:(id)v { return __keys(self, v); }
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

@implementation CPArray (WMKeyValueCoding)

+ (id) _valueForKeyPathElement:(id)element onObject:(id)obj { return __valueForKeyPathElement_onObject(self, element, obj); }
+ (id) _valueForKey:(id)key onObject:(id)obj { return __valueForKey_onObject(self, key, obj); }
+ (void) _setValue:(id)v forKey:(id)key onObject:(id)obj { return __setValue_forKey_onObject(self, v, key, obj); }
+ (id) _listOfPossibleKeyNames:(id)key { return __listOfPossibleKeyNames(self, key); }

- (id) evaluateExpression:(id)expression { 	return __evaluateExpression(self, expression); }
- (id) targetObjectAndKeyForKeyPath:(id)keyPath { return __targetObjectAndKeyForKeyPath(self, keyPath); }
- (void) setValue:(id)v forKey:(id)key { return __setValue_forKey(self, v, key); }
- (id) valueForKey:(id)key { return __valueForKey(self, key); }
- (id) valueForKeyPath:(id)keyPath { return __valueForKeyPath(self, keyPath); }
- (void) setValue:(id)v forKeyPath:(id)keyPath { return __setValue_forKeyPath(self, v, keyPath); }
- (id) int:(id)v { return __int(self, v); }
- (id) length:(id)v { return __length(self, v); }
- (id) keys:(id)v { return __keys(self, v); }
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
