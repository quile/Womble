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

@import "Object.j"
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

    [WMLog debug:"Checking if " + expression + " is key path"];
    if ([WMUtility expressionIsKeyPath:expression]) {
        [WMLog debug:"expression " + expression + " is key path"];
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
		var charAt = chars[i];

		if (charAt == '\\') {
			extracted = extracted + chars[i] + chars[i+1];
			i++;
			continue;
		}
		if (charAt == terminator) {
			if ([WMUtility isBalanced:balanced]) {
				return extracted;
			}
		}

		if (!isQuoting) {
			if (charAt.match(QUOTE_RE)) {
				isQuoting = true;
				outerQuoteChar = charAt;
				balanced[charAt]++;
			} else if (charAt.match(OPEN_RE)) {
				balanced[charAt]++;
			} else if (charAt == ']') {
				balanced['[']--;
			} else if (charAt == '}') {
				balanced['{']--;
			} else if (charAt == ')') {
				balanced['(']--;
			}
		} else {
			if (charAt == outerQuoteChar) {
				isQuoting = false;
				outerQuoteChar = '';
				balanced[charAt] ++;
			}
		}

		extracted = extracted + charAt;
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
