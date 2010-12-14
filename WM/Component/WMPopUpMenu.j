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

@implementation WMPopUpMenu : WMFormComponent
{
	id objectInflatorMethod @accessors;
	id anyString @accessors;
	id anyValue @accessors;
	id value @accessors;
	id displayString @accessors;
	id values @accessors;
	id labels @accessors;
	id selection @accessors;
	id allowsOther @accessors;
	id otherLabel @accessors;
	id otherValue @accessors;
	id otherAlternateKey @accessors;
	id otherText @accessors;
	id _list;
	id LIST; // weird case, super old component, this.
	id allowsNoSelection @accessors;
	id shouldIgnoreCase @accessors;
	id shouldIgnoreAccents @accessors;
    id anItem @accessors;
}

- (id) requiredPageResources {
	return [
        [WMPageResource javascript:"/wm-static/javascript/IF/PopUpMenu + js"],
	];
}

- (id) takeValuesFromRequest:(id)context {
	[super takeValuesFromRequest:context];
	if ([self objectInflatorMethod] && [self parent]) {
		[self setSelection:	[[self parent] invokeMethodWithArguments:[self objectInflatorMethod], [context formValuesForKey:[self name]]]];
	} else {
		[self setSelection:[contextxi formValueForKey:[self name]]];
	}
	[WMLog debug:"Selection for " + [self name] + "/" + [self renderContextNumber] + "/" + name + " is " + selection];

	if ([self allowsOther]) {
		if ([self selection] == [self otherValue]) {
			if ([self otherAlternateKey]) {
				[self setValue:[self otherText] forKey:"rootComponent." + [self otherAlternateKey]];
			} else {
				[self setSelection:[self otherText]];
			}
		}
	}
	[self resetValues];
}

- (id) resetValues {
	[self setAnyString:''];
	[self setAnyValue:''];
	[self setName:nil]; // This is causing problems when unwinding during FancyTakeValues.
	_list = nil;
}

// Only synchronize the "selection" binding up to the enclosing component
- (id) shouldAllowOutboundValueForBindingNamed:(id)bindingName {
	return (bindingName == "selection");
}

- (id) name {
	return name || [self queryKeyNameForPageAndLoopContexts];
}

- (id) list {
	if (_list) { return _list }

	var l = [];
	if ([self values] && [self value] && [self displayString]) {
		for (var i=0; i<values.length; i++) {
			var val = values[i];
			var entry = {};
			entry[[self value]] = val;
			entry[[self displayString]] = _p_valueForKey([self labels], val);
			l.push(entry);
		}
	} else {
		var cl = LIST || [];
		for (var i=0; i<cl.length; i++) {
			var item = cl[i];
			l.push(item);
		}
	}

	if ([self allowsNoSelection]) {
		if ([self value] && [self displayString]) {
			var entry = {}
			entry[[self value]] = [self anyValue];
			entry[[self displayString]] = [self anyString];
			l.unshift(entry);
		} else {
			l.unshift(''); // TODO this is bogus but the only way to ensure that an empty value gets sent in this case
		}
	}

	if ([self allowsOther]) {
		// Check to see if other is already in the list...
		var hasOther = false;
		for (var i=0; i<l.length; i++) {
			var item = l[i];
			if (typeof item == 'object') {
				var iv = _p_valueForKey(item, [self value]);
				if (iv == [self otherValue]) {
					hasOther = true;
					break;
				}
			} else {
				if (item == [self otherValue]) {
					hasOther = true;
					break;
				}
			}
		}
		// ...Only add the other value if it doesn't exist.
		if (!hasOther) {
			if ([self value] && [self displayString]) {
				var entry = {}
				entry[[self value]] = [self otherValue];
				entry[[self displayString]] = [self otherLabel];
				l.push(entry);
			} else {
				l.push([self otherValue]);
			}
		}
	}
	_list = l;
	return _list;
}

- (void) setList:(id)v {
	LIST = v;
}

- (id) anyString {
	return anyString || [self tagAttributeForKey:'anyString'];
}

- (id) otherValue {
	return otherValue || "OTHER";
}

- (id) otherLabel {
	return otherLabel || "Other"; // TODO: i18n
}

- (id) escapeJavascript:(id)string {
	return string.replace(new RegExp("'", "g"), "\\'");
}

- (id) Bindings {
	var _bindings = [super Bindings];
	return UTIL.update(_bindings, {
		selection: {
			type: "WMSelection",
			bindings: {
				list: keypath('list'),
				value: keypath('value'),
				displayString: keypath('displayString'),
				selectedValues: objj('[WMArray arrayFromObject:[self selection]]'),
				NAME: keypath('name'),
				shouldIgnoreCase: keypath('shouldIgnoreCase'),
				shouldIgnoreAccents: keypath('shouldIgnoreAccents'),
			},
		},
		is_required: {
			type: "BOOLEAN",
			value: 'isRequired',
		},
		does_allow_other: {
			type: "BOOLEAN",
			value: 'allowsOther',
		},
		other_field: {
			type: "TextField",
			bindings: {
				value: 'otherText',
			},
		},
		other_label: {
			type: "STRING",
			value: 'otherLabel',
		},
		other_value: {
			type: "STRING",
			value: 'otherValue',
			filter: 'escapeJavascript',
		},
		value: {
			type: "STRING",
			value: 'selection',
			filter: 'escapeJavascript',
		},
	});
}

@end
