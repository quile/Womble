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
	if (item && item.isa && [item respondsToSelector:@SEL("valueForKey:")]) {
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
