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

var UTIL = require("util.js");

@import <WM/Component/WMFormComponent.j>
@import <WM/WMPageResource.j>

@implementation WMSubmitButton : WMFormComponent
{
	id name @accessors;
	id directAction @accessors;
	id targetComponent @accessors;
	id alternateValue @accessors;
	id canOnlyBeClickedOnce @accessors;
	id shouldValidateForm @accessors;
}

- (id) requiredPageResources {
	return [
        [WMPageResource javascript:"/wm-static/javascript/WM/SubmitButton.js"],
	];
}

- (id) init {
	var instance = [super init];
	[instance setShouldValidateForm:1];
	return instance;
}

- (id) name {
	if (name) { return name }
	if ([self directAction]) {
		[WMLog debug:"We have a direct action, so returning _ACTION:" + [self targetComponent] + "/" + [self directAction]];
		return "_ACTION:" + [self targetComponent] + "/" + [self directAction];
	}
	return [self queryKeyNameForPageAndLoopContexts];
}

/*
- _deprecated_uniqueId {
	var uniqueNumber = [self pageContextNumber];
	uniqueNumber =~ tr/[0-9]/[A-Z]/;
	uniqueNumber =~ s/\./_/g;
	return uniqueNumber;
}
*/

- (id) _alternateValue {
	return [self alternateValue]
	    || [self tagAttributeForKey:"alternateValue"]
	    || "...";  // TODO: hmm - at least localize
}

- (id) shouldValidateForm {
	return shouldValidateForm || [self tagAttributeForKey:"shouldValidateForm"];
}

- (id) Bindings {
	var _bindings = [super Bindings];
	return UTIL.update(_bindings, {
		button_name: {
			type: "STRING",
			value: 'name',
		},
		has_button_value: {
			type: "BOOLEAN",
			value: 'value',
		},
		button_value: {
			type: "STRING",
			value: 'value',
		},
		content: {
			type: "CONTENT",
		},
		is_single_click: {
			type: "BOOLEAN",
			value: 'canOnlyBeClickedOnce',
		},
		alternate_value: {
			type: "STRING",
			value: '_alternateValue',
		},
		should_validate_form: {
			type: "BOOLEAN",
			value: 'shouldValidateForm',
		},
	});
}


@end
