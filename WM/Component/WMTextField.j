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

var UTIL = require("util")

@import <WM/Component/WMFormComponent.j>

@implementation WMTextField : WMFormComponent
{
	id name @accessors;
	id size @accessors;
	id maxLength @accessors;
	id value @accessors;
	id shouldEnableClientSideScripting @accessors;
}

- (id) requiredPageResources {
	return [
        [WMPageResource javascript:"/wm-static/javascript/WM/TextField.js"],
	];
}

- (id) resetValues {
	name = nil;
	size = nil;
	maxLength = nil;
	value = nil;
}

- (id) takeValuesFromRequest:(id)context {
	[super takeValuesFromRequest:context];
	value = [context formValueForKey:name];
	[WMLog debug:"Value of input field " + name + " is " + value];
}

- (id) name {
	return name || [self queryKeyNameForPageAndLoopContexts];
}

// TODO make this a real escape.
- (id) escapeDoubleQuotes:(id)str {
	if (!str) { return nil }
	return str.replace(new RegExp('"', "g"), '&quot;');
}

- (id) Bindings {
	return {
		// TODO implement binding inheritance
		name: {
			type: "STRING",
			value: 'name',
		},
		size: {
			type: "STRING",
			value: 'size',
		},
		max_length: {
			type: "STRING",
			value: 'maxLength',
		},
		value: {
			type: "STRING",
			value: 'value',
			filter: 'escapeDoubleQuotes',
		},
		should_enable_client_side_scripting: {
			type: "BOOLEAN",
			value: 'shouldEnableClientSideScripting',
		},
	};
}

@end
