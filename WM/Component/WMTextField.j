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
		NAME: {
			type: "STRING",
			value: 'name',
		},
		SIZE: {
			type: "STRING",
			value: 'size',
		},
		MAX_LENGTH: {
			type: "STRING",
			value: 'maxLength',
		},
		VALUE: {
			type: "STRING",
			value: 'value',
			filter: 'escapeDoubleQuotes',
		},
		SHOULD_ENABLE_CLIENT_SIDE_SCRIPTING: {
			type: "BOOLEAN",
			value: 'shouldEnableClientSideScripting',
		},
	};
}

@end
