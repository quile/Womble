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
		name: {
			type: "STRING",
			value: 'name',
		},
		value: {
			type: "STRING",
			value: 'value',
		},
		is_checked: {
			type: "BOOLEAN",
			value: 'isChecked',
		},
		tag_attributes: {
			type: "ATTRIBUTES",
		},
	});
}

@end
