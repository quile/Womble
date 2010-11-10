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

@import <WM/Component/WMFormComponent.j>
@import <WM/WMPageResource.j>

var UTIL = require("util");

@implementation WMScrollingList : WMFormComponent
{
	id name @accessors;
	id objectInflatorMethod @accessors;
	id list @accessors;
	id value @accessors;
	id displayString @accessors;
	id selection @accessors;
	id isMultiple @accessors;
	id anyString @accessors;
	id anyValue @accessors;
	id size @accessors;
}

- (id) requiredPageResources {
	return [
        [WMPageResource javascript:"/wm-static/javascript/WM/ScrollingList.js"],
	];
}

- (id) init {
	[super init];
	anyValue = "";
	return self;
}

- (id) takeValuesFromRequest:(id)context {
	[super takeValuesFromRequest:context];
	if ([self objectInflatorMethod] && [self parent]) {
		[self setSelection:	[[self parent] invokeMethodWithArguments:[self objectInflatorMethod], [context formValuesForKey:[self name]]]];
	} else {
		if ([self isMultiple]) {
			[self setSelection:[context formValuesForKey:[self name]]];
		} else {
			[self setSelection:[context formValueForKey:[self name]]];
		}
	}
}

- (id) name {
	return name || [self queryKeyNameForPageAndLoopContexts];
}

- (id) Bindings {
	var _bindings = [super Bindings];
	return UTIL.update(_bindings, {
		selection: {
			type: "Selection",
			bindings: {
				LIST: 'list',
				VALUE: 'value',
				DISPLAY_STRING: 'displayString',
				SELECTED_VALUES: objj('[WMArray arrayFromObject:[self selection]]'),
				NAME: 'name',
				SIZE: 'size',
				IS_MULTIPLE: 'isMultiple',
				ANY_STRING: 'anyString',
				ANY_VALUE: 'anyValue',
			},
		}
	});
}

@end
