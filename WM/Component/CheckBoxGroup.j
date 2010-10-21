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

@import <WM/Component/ScrollingList.j>
@import <WM/PageResource.j>

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
	var v;

	if (item && item['isa'] && [item respondsToSelector:@SEL('valueForKey:')]) {
		v = [item valueForKey:[self value]];
	} else if (_p_isHash(item) && [self value] in item) {
		v = item[[self value]];
	} else {
		v = item;
	}

	if (v == "") { return false }
	if (!_p_isArray([self selection])) { return false }
	for (var i=0; i<[[self selection] count]; i++) {
		var selectedValue = [self selection][i];
		if (typeof selectedValue != "object") {
			if (selectedValue == value) { return true }
			if (selectedValue  && selectedValue.match(/^[0-9\.]+$/) &&
				v && v.match(/^[0-9\.]+$/) &&
				selectedValue == v) {
				return true;
			}
			continue;
		}
		if (selectedValue && selectedValue.isa && [selectedValue respondsToSelector:@SEL("valueForKey:")]) {
			if ([selectedValue valueForKey:[self value]] == value) { return true }
		} else {
			if ([self value] in selectedValue && selectedValue[[self value]]) { return true }
		}
	}
	return false;
}

- (id) displayStringForItem:(id)item {
	return _p_valueForKey(item, [self displayString]);
	//if (item && item.isa && [item respondsToSelector:@SEL("valueForKey:")]) {
	//	return [item valueForKey:[self displayString]];
	//}
	//if (_p_isHash(item)) {
	//	if ([self displayString] in item) {
	//		return item[[self displayString]];
	//	} else {
	//		return nil;
	//	}
	//}
	//return item;
}

- (id) valueForItem:(id)item {
	return _p_valueForKey(item, [self value]);
	//var v;
	//if (UNIVERSAL::can(item, "valueForKey")) {
	//	return [item valueForKey:self->value()];
	//}
	//if (IFDictionary.isHash(item)) {
	//	if (exists(item[[self value]])) {
	//		return item[[self value]];
	//	} else {
	//		return null;
	//	}
	//}
	//return item;
}

- name {
	// This has to be pageContextNumber so that the checkboxes
	// all get this component's unique id
	return name || [self pageContextNumber];
}

- (id) Bindings {
	var _bindings = [super Bindings];
	return UTIL.update(_bindings, {
		NAME: {
			type: "STRING",
			value: 'name',
		},
		LIST: {
			type: "LOOP",
			list: 'list',
			item: "anItem",
		},
		VALUE: {
			type: "STRING",
			value: objj('[self valueForItem:[self anItem]]'),
		},
		IS_SELECTED: {
			type: "BOOLEAN",
			value: objj('[self itemIsSelected:[self anItem]]'),
		},
		DISPLAY_STRING: {
			type: "STRING",
			value: objj('[self displayStringForItem:[self anItem]]'),
		},
		SHOULD_ENABLE_CLIENT_SIDE_SCRIPTING: {
			type: "BOOLEAN",
			value: 'shouldEnableClientSideScripting',
		},
		SHOULD_RENDER_IN_TABLE: {
			type: "BOOLEAN",
			value: 'shouldRenderInTable',
		},
		INIT_CODE: {
			type: "STRING",
			value: objj('[self tagAttributeForKey:"init"]'),
		},
		HAS_INIT_CODE: {
			type: "BOOLEAN",
			value: objj('[self tagAttributeForKey:"init"]'),
		},
		CHECKBOXES: {
			type: "REGION",
			name: "checkboxes",
		},
		LABELS: {
			type: "REGION",
			name: "labels",
		},
	});
}

@end
