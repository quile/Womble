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


@implementation WMRadioButton : WMFormComponent
{
	id value @accessors;
	id isChecked @accessors;
	id isNegated @accessors;
}

- (id) takeValuesFromRequest:(id)context {
	[super takeValuesFromRequest:context];
	[self setValue:[context formValueForKey:[self name]]];
	[WMLog debug:"Value of input field " + [self name] + " is " + [self value]];
}

- (id) name {
	return name || [self queryKeyNameForPageAndLoopContexts];
}

- isChecked {
	if ([self isNegated]) {
		return !isChecked;
	}
	return isChecked;
}

- (id) Bindings {
	var _bindings = [super Bindings];
	return UTIL.update(_bindings, {
		NAME: {
			type: "STRING",
			value: 'name',
		},
		VALUE: {
			type: "STRING",
			value: 'value',
		},
		IS_CHECKED: {
			type: "BOOLEAN",
			value: 'isChecked',
		},
		TAG_ATTRIBUTES: {
			type: "ATTRIBUTES",
		},
	});
}

@end
