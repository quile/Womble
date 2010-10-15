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

@import <WM/Component/PopUpMenu.j>
@import <WM/PageResource.j>


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

- (id) name {
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
			value: q'shouldRenderInTable',
		},
		IS_VERTICAL_LAYOUT: {
			type: "BOOLEAN",
			value: 'isVerticalLayout',
		},
		BUTTONS: {
			type: "REGION",
			name: 'buttons',
		},
		LABELS: {
			type: "REGION",
			name: 'labels',
		},
	});
}

@end
