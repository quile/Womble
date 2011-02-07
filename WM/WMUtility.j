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

@import "WMObject.j"
@import "Helpers.js"

var KP_RE = new RegExp('^[A-Za-z_\(\)]+[A-Za-z0-9_#\@\.\(\)\"]*$');
var KP_RE_PLUS = new RegExp('^[A-Za-z_\(\)]+[A-Za-z0-9_#\@]*[\(\.]+');
var QUOTE_RE = new RegExp('["' + "']");
var OPEN_RE = new RegExp("[\[\{\(]");


@implementation WMUtility : WMObject

+ (Boolean) expressionIsKeyPath:(id)expression {
    if (!expression) { return false }
    if ( expression.match(KP_RE) ) { return true }
    return expression.match(KP_RE_PLUS);
}

+ (id) evaluateExpression:(id)expression inComponent:(id)component context:(id)context {
    if (!component) { return nil }

    if (typeof expression == 'function') {
        try {
            return expression(component, context);
        } catch (e) {
            [WMLog error:"Failed to evaluate expression " + e + " in " + component];
            return nil;
        }
    }

    // if it's already an object, just return it.  This is for the case
    // where bindings are hardcoded as arrays or dictionaries
    if (typeof expression == "object") {
        return expression;
    }

    if ([WMUtility expressionIsKeyPath:expression]) {
        return [component valueForKeyPath:expression];
    }

    // hack!  trying to do away with this by making
    // these non-keypath ones into js functions
    var foo = self;
    self = component;
    try {
        var rv = eval(expression);
        [WMLog debug:expression + " " + rv];
        return rv;
    } catch (e) {
        [WMLog warning:"Expression (" + expression + ") evaluation failure: " + e];
    } finally {
        self = foo;
    }
    return expression;
}

+ (id) keyPathElementsForPath:(id)path {
    if (!path.match(/\(/)) {
        return path.split(".").map(function (key) { return { 'key': key } });
    }

    var KEY_RE = new RegExp("([a-zA-Z0-9_\@]+)\\(");
	var keyPathElements = [];
	while (1) {
        var bits = _p_2_split(".", path);
		var firstElement = bits[0],
            rest = bits[1];
        if (!firstElement) { break; }
        //[WMLog debug:"Split path into " + firstElement + " and " + rest];
		var match = firstElement.match(KEY_RE);
        if (match) {
			var key = match[1];
			var element = new RegExp(_p_quotemeta(key + "("));
			path = path.replace(element, "");
			var argumentString = [WMUtility extractDelimitedChunkFrom:path terminatedBy:')'];
			var quotedArguments = _p_quotemeta(argumentString + ")") + "\\.?";
			// extract arguments:
			var arguments = [];
			while (1) {
				var argument = [WMUtility extractDelimitedChunkFrom:argumentString terminatedBy:","];
				if (!argument) { break }
				arguments.push(_p_trim(argument));
				var quotedArgument = _p_quotemeta(argument) + ",?\\s*";
				argumentString = argumentString.replace(new RegExp(quotedArgument), "");
			}
			keyPathElements.push({ key: key, arguments: arguments });
            //[WMLog debug:"Arguments = " + arguments];
            path = path.replace(new RegExp(quotedArguments), "");
		} else {
            if (firstElement) {
                keyPathElements.push({ key: firstElement });
            }
			path = rest;
		}
		//IF::Log::debug("Left to process: <$path>");
        if (!rest) { break }
	}
    //[WMLog debug:keyPathElements.toSource()];
	return keyPathElements;
}

// It's easier to do it this way than to import Text::Balanced
+ (id) extractDelimitedChunkFrom:(id)chunk terminatedBy:(id)terminator {
	var extracted = "";
	var balanced = { '(': 0, '{': 0, '[': 0, '"': 0, "'": 0 };
	var isQuoting = false;
	var outerQuoteChar = '';

	var chars = chunk.split("");
	for (var i = 0; i < chars.length; i++) {
		var chrAt = chars[i];

		if (chrAt == '\\') {
			extracted = extracted + chars[i] + chars[i+1];
			i++;
			continue;
		}
		if (chrAt == terminator) {
			if ([WMUtility isBalanced:balanced]) {
				return extracted;
			}
		}

		if (!isQuoting) {
			if (chrAt.match(QUOTE_RE)) {
				isQuoting = true;
				outerQuoteChar = chrAt;
				balanced[chrAt]++;
			} else if (chrAt.match(OPEN_RE)) {
				balanced[chrAt]++;
			} else if (chrAt == ']') {
				balanced['[']--;
			} else if (chrAt == '}') {
				balanced['{']--;
			} else if (chrAt == ')') {
				balanced['(']--;
			}
		} else {
			if (chrAt == outerQuoteChar) {
				isQuoting = false;
				outerQuoteChar = '';
				balanced[chrAt] ++;
			}
		}

		extracted = extracted + chrAt;
	}
	if ([WMUtility isBalanced:balanced]) {
		return extracted;
	} else {
		[WMLog error:"Error parsing keypath chunk; unbalanced '" + [WMUtility unBalanced:balanced] + "'"];
	}
	return "";
}

+ (id) isBalanced:(id)balanced {
    for (var ch in balanced) {
		if (ch.match(OPEN_RE) && balanced[ch] != 0) { return false }
		if (ch.match(QUOTE_RE) && balanced[ch] % 2 != 0) { return false }
	}
	return true;
}

+ (id) unBalanced:(id)balanced {
	for (var ch in balanced) {
        if (ch.match(OPEN_RE) && balanced[ch] != 0) { return ch }
		if (ch.match(QUOTE_RE) && balanced[ch] % 2 != 0) { return ch }
	}
    return nil;
}

@end
