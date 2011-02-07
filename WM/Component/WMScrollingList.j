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

var UTIL = require("util");

@implementation WMScrollingList : WMFormComponent
{
	id name @accessors;
	id objectInflatorMethod @accessors;
	id _list;
	id value @accessors;
	id displayString @accessors;
	id selection @accessors;
	id isMultiple @accessors;
	id anyString @accessors;
	id anyValue @accessors;
	id size @accessors;
    id anItem @accessors;
}

- (id) requiredPageResources {
	return [
        [WMPageResource javascript:"/wm-static/javascript/WM/ScrollingList.js"],
	];
}

- (id) init {
	[super init];
	anyValue = "";
    size = 10;
	return self;
}

- (id) takeValuesFromRequest:(id)context {
	[super takeValuesFromRequest:context];
	if ([self objectInflatorMethod] && [self parent]) {
		[self setSelection:	[[self parent] invokeMethodWithArguments:[self objectInflatorMethod], [context formValuesForKey:[self name]]]];
	} else {
		if ([self isMultiple]) {
			[self setSelection:[context formValuesForKey:[self name]]];
		} else {
			[self setSelection:[context formValueForKey:[self name]]];
		}
	}
}

- (id) name {
	return name || [self queryKeyNameForPageAndLoopContexts];
}

- (id) list {
    return _list;
}

- (void) setList:(id)v {
    [WMLog debug:"Setting list to " + v];
    _list = v;
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
				name: keypath('name'),
				size: keypath('size'),
				isMultiple: keypath('isMultiple'),
				anyString: keypath('anyString'),
				anyValue: keypath('anyValue'),
			},
		}
	});
}

@end
