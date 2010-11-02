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

@import <WM/WMComponent.j>
@import <WM/WMPageResource.j>

var UTIL = require("util");

@implementation WMSelection : WMComponent {
{
	id _list;
	id listType @accessors;
	id values @accessors;
	id labels @accessors;
	id anyString @accessors;
	id anyValue @accessors;
	id shouldIgnoreCase @accessors;
	id shouldIgnoreAccents @accessors;
	id size @accessors;
}

- (id) init {
	size = 1;
	return self;
}

- (id) takeValuesFromRequest:(id)context {
	[WMLog debug:"Form value for selection box " + [self name] + " is " + [context formValueForKey:[self name]]];
	[WMLog debug:"Selection page context number is " + [self pageContextNumber]];
	[super takeValuesFromRequest:context];
}

- (id) list {
	var list;
	if ([self listType] == "RAW") {
		list = [self rawList];
	} else {
		list = LIST || [];
	}
	if ([self allowsNoSelection]) {
		if ([self value] && [self displayString]) {
			var entry = {};
			entry[[self value]] = [self anyValue];
			entry[[self displayString]] = [self anyString];
			list.unshift(entry);
		} else {
			list.unshift({});
		}
	}
	return list;
}

- (void) setList:(id)value {
	_list = value;
}

- (id) displayStringForItem:(id)item {
	if (item && item.isa && [item respondsToSelector:@SEL("valueForKey")]) {
		return [item valueForKey:[self displayString]];
	}
	if (_p_isHash(item)) {
		if ([self displayString] in item) {
			return item[[self displayString]];
		} else {
			return nil;
		}
	}
	return item;
}

- (id) valueForItem:(id)item {
	var val;
	if (item && item.isa && [item respondsToSelector:@SEL("valueForKey")]) {
		return [item valueForKey:[self value]];
	}
	if (_p_isHash(item)) {
		if ([self value] in item) {
			return item[[self value]];
		} else {
			return nil;
		}
	}
	return item;
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
	if (!_p_isArray([self selectedValues])) {
		return false;
	}

	for (var i=0; i<[self selectedValues].length; i++) {
		var selectedValue = [self selectedValues][i];

		if (typeof selectedValue != "object") {
			if ([self value:selectedValue isEqualTo:val]) { return true }

			if (selectedValue.match(/^[0-9\.]+$/) && value.match(/^[0-9\.]+$/) && selectedValue == value) {
				return true;
			}
			continue;
		}
		if (selectedValue && selectedValue.isa && [selectedValue respondsToSelector:@SEL("valueForKey")]) {
			return [self value:[selectedValue valueForKey:[self value]] isEqualTo:val];
		} else {
			return [self value:selectedValue[[self value]] isEqualTo:val];
		}
	}
	return false;
}

- (id) value:(id)a isEqualTo:(id)b {
	// unicode hammer...?
	/*
	if ([self shouldIgnoreAccents]) {
		a = unac_string("utf-8", a);
		b = unac_string("utf-8", b);
	}
	*/

	if ([self shouldIgnoreCase]) {
		a = a.toLowerCase();
		b = b.toLowerCase();
	}

	return (a == b);
}

- (void) setValues:(id)vs {
	values = vs;

	if (labels) {
		_list = [self listFromLabelsAndValues];
	}
}

- (void) setLabels:(id)ls {
	labels = ls;

	if (values) {
		_list = [self listFromLabelsAndValues];
	}
}

- (id) listFromLabelsAndValues {
	if (!values || !labels) { return [] }

	var l = [];
	for (var i=0; i<values.length; i++) {
		var value = values[i];
		l.push({ VALUE: value, LABEL: lables[value] });
	}
	return l;
}

- (id) Bindings {
	var _bindings = [super Bindings];
	return UTIL.update(_bindings, {
		NAME: {
			type: "STRING",
			value: 'name',
		},
		SIZE: {
			type: "STRING",
			value: 'size',
		},
		IS_MULTIPLE: {
			type: "BOOLEAN",
			value: objj('[self size] > 1'),
		},
		LIST: {
			type: "LOOP",
			list: 'list',
			item: "anItem",
		},
		VALUE: {
			type: "STRING",
			value: 'valueForItem(anItem)',
		},
		IS_SELECTED: {
			type: "BOOLEAN",
			value: 'itemIsSelected(anItem)',
		},
		DISPLAY_STRING: {
			type: "STRING",
			value: 'displayStringForItem(anItem)',
		},
		TAG_ATTRIBUTES: {
			type: "ATTRIBUTES",
		},
		SHOULD_ENABLE_CLIENT_SIDE_SCRIPTING: {
			type: "BOOLEAN",
			value: 'shouldEnableClientSideScripting',
		},
		UNIQUE_ID: {
			type: "STRING",
			value: 'uniqueId',
		},
	});
}

@end
