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
    id _v @accessors(property=value);
    id _displayString @accessors(property=displayString);
    id _selectedValues @accessors(property=selectedValues);
	id listType @accessors;
	id values @accessors;
	id labels @accessors;
	id anyString @accessors;
	id anyValue @accessors;
	id shouldIgnoreCase @accessors;
	id shouldIgnoreAccents @accessors;
	id size @accessors;
    id allowsNoSelection @accessors;
}

- (id) init {
	size = 1;
	return [super init];
}

- (id) takeValuesFromRequest:(id)context {
	[WMLog debug:"Form value for selection box " + [self name] + " is " + [context formValueForKey:[self name]]];
	[WMLog debug:"Selection page context number is " + [self pageContextNumber]];
	[super takeValuesFromRequest:context];
}

- (id) list {
	var l;
	if ([self listType] == "RAW") {
		l = [self rawList];
	} else {
		l = _list || [];
	}
	if ([self allowsNoSelection]) {
		if ([self value] && [self displayString]) {
			var entry = {};
			entry[[self value]] = [self anyValue];
			entry[[self displayString]] = [self anyString];
			l.unshift(entry);
		} else {
			l.unshift({});
		}
	}
	return l;
}

- (void) setList:(id)v {
	_list = v;
}

- (id) displayStringForItem:(id)item {
    if (typeof item === "string") { return item }
	return __valueForKey_onObject(self, [self displayString], item);
}

- (id) valueForItem:(id)item {
    if (typeof item === "string") { return item }
	return __valueForKey_onObject(self, [self value], item);
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
		l.push({ VALUE: value, LABEL: labels[value] });
	}
	return l;
}

- (id) Bindings {
	var _bindings = [super Bindings];
	return UTIL.update(_bindings, {
		name: {
			type: "STRING",
			value: 'name',
		},
		size: {
			type: "STRING",
			value: 'size',
		},
		is_multiple: {
			type: "BOOLEAN",
			value: objj('[self size] > 1'),
		},
		list: {
			type: "LOOP",
			list: 'list',
			item: "anItem",
		},
		value: {
			type: "STRING",
			value: 'valueForItem(anItem)',
		},
		is_selected: {
			type: "BOOLEAN",
			value: 'itemIsSelected(anItem)',
		},
		display_string: {
			type: "STRING",
			value: 'displayStringForItem(anItem)',
		},
		tag_attributes: {
			type: "ATTRIBUTES",
		},
		should_enable_client_side_scripting: {
			type: "BOOLEAN",
			value: 'shouldEnableClientSideScripting',
		},
		unique_id: {
			type: "STRING",
			value: 'uniqueId',
		},
	});
}

@end
