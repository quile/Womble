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
		BUTTON_NAME: {
			type: "STRING",
			value: 'name',
		},
		HAS_BUTTON_VALUE: {
			type: "BOOLEAN",
			value: 'value',
		},
		BUTTON_VALUE: {
			type: "STRING",
			value: 'value',
		},
		CONTENT: {
			type: "CONTENT",
		},
		IS_SINGLE_CLICK: {
			type: "BOOLEAN",
			value: 'canOnlyBeClickedOnce',
		},
		ALTERNATE_VALUE: {
			type: "STRING",
			value: '_alternateValue',
		},
		SHOULD_VALIDATE_FORM: {
			type: "BOOLEAN",
			value: 'shouldValidateForm',
		},
	});
}


@end
