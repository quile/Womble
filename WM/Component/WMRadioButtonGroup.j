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

@import <WM/Component/WMPopUpMenu.j>
@import <WM/WMPageResource.j>

var UTIL = require("util");

@implementation WMRadioButtonGroup : WMPopUpMenu
{
	id isVerticalLayout @accessors;
	id shouldRenderInTable @accessors;
}

- (id) requiredPageResources {
	return [
        [WMPageResource javascript:"/wm-static/javascript/WM/RadioButtonGroup.js"],
	];
}

- (id) init {
	[super init];
	isVerticalLayout = true;
}

- (id) takeValuesFromRequest:(id)context {
	[super takeValuesFromRequest:context];
	if ([self objectInflatorMethod] && [self parent]) {
		[self setSelection:	[[self parent] invokeMethodWithArguments:[self objectInflatorMethod], [context formValueForKey:[self name]]]];
	} else {
		[self setSelection:[context formValueForKey:[self name]]];
	}
}

- (id) itemIsSelected:(id)item {
	var val;
	if (item && item.isa && [item respondsToSelector:@SEL("valueForKey")]) {
		val = [item valueForKey:[self value]];
	} else if (_p_isHash(item) && [self value] in item) {
		val = item[[self value]];
	} else {
		val = item;
	}

	if (val == "") { return false }
	return (val == [self selection]);
}

- (id) displayStringForItem:(id)item {
    if (typeof item === "string") { return item }
	return __valueForKey_onObject(self, [self displayString], item);
}

- (id) valueForItem:(id)item {
    if (typeof item === "string") { return item }
    return __valueForKey_onObject(self, [self value], item);
}

- (id) name {
	return name || [self pageContextNumber];
}

- (id) Bindings {
	var _bindings = [super Bindings];
	return UTIL.update(_bindings, {
		name: {
			type: "STRING",
			value: 'name',
		},
		list: {
			type: "LOOP",
			list: 'list',
			item: "anItem",
		},
		value: {
			type: "STRING",
			//value: objj('[self valueForItem:[self anItem]]'),
            value: keypath('valueForItem(anItem)'),
		},
		is_selected: {
			type: "BOOLEAN",
			//value: objj('[self itemIsSelected:[self anItem]]'),
            value: keypath('itemIsSelected(anItem)'),
		},
		display_string: {
			type: "STRING",
			//value: objj('[self displayStringForItem:[self anItem]]'),
            value: keypath('displayStringForItem(anItem)'),

		},
		should_enable_client_side_scripting: {
			type: "BOOLEAN",
			value: 'shouldEnableClientSideScripting',
		},
		should_render_in_table: {
			type: "BOOLEAN",
			value: 'shouldRenderInTable',
		},
		is_vertical_layout: {
			type: "BOOLEAN",
			value: 'isVerticalLayout',
		},
		buttons: {
			type: "REGION",
			name: 'buttons',
		},
		labels: {
			type: "REGION",
			name: 'labels',
		},
	});
}

@end
