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

@import <WM/Component/WMScrollingList.j>
@import <WM/WMPageResource.j>

var UTIL = require("util");

@implementation WMCheckBoxGroup : WMScrollingList
{
	id shouldRenderInTable @accessors;
}

- (id) requiredPageResources {
	return [
        [WMPageResource javascript:"/wm-static/javascript/WM/CheckBoxGroup.js"],
	];
}

- (id) takeValuesFromRequest:(id)context {
	[super takeValuesFromRequest:context];
	if ([self objectInflatorMethod] && [self parent]) {
		[self setSelection:	[[self parent] invokeMethodWithArguments:[self objectInflatorMethod], [context formValuesForKey:[self name]]]];
	} else {
		[self setSelection:[context formValuesForKey:[self name]]];
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
	if (!_p_isArray([self selection])) { return false }

	for (var i=0; i<[self selection].length; i++) {
		var selectedValue = [self selection][i];

		if (typeof selectedValue != "object") {
			if (selectedValue == val) { return true }
			if (selectedValue.match(/^[0-9\.]+$/) && value.match(/^[0-9\.]+$/) && selectedValue == value) {
				return true;
			}
			continue;
		}
		if (selectedValue && selectedValue.isa && [selectedValue respondsToSelector:@SEL("valueForKey:")]) {
			return [selectedValue valueForKey:[self value]] == val; //[self value:[selectedValue valueForKey:[self value]] isEqualTo:val];
		} else {
			return selectedValue[[self value]] == val; //[self value:selectedValue[[self value]] isEqualTo:val];
		}
	}
	return false;
}

- (id) displayStringForItem:(id)item {
    if (typeof item === "string") { return item }
	return __valueForKey_onObject(self, [self displayString], item);
}

- (id) valueForItem:(id)item {
    if (typeof item === "string") { return item }
	return __valueForKey_onObject(self, [self value], item);
}

- name {
	// This has to be pageContextNumber so that the checkboxes
	// all get this component's unique id
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
			value: keypath('valueForItem(anItem)'),
		},
		is_selected: {
			type: "BOOLEAN",
			value: keypath('itemIsSelected(anItem)'),
		},
		display_string: {
			type: "STRING",
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
		init_code: {
			type: "STRING",
			value: objj('[self tagAttributeForKey:"init"]'),
		},
		has_init_code: {
			type: "BOOLEAN",
			value: objj('[self tagAttributeForKey:"init"]'),
		},
		checkboxes: {
			type: "REGION",
			name: "checkboxes",
		},
		labels: {
			type: "REGION",
			name: "labels",
		},
	});
}

@end
