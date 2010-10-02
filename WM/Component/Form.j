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

@import <WM/Component.j>
@import <WM/Component/Hyperlink.j>
@import <WM/PageResource.j>

var UTIL = require("util.js")

@implementation WMForm : WMHyperlink
{
	id method @accessors;
	id shouldEnableClientSideScripting @accessors;
	id encType @accessors;
	id name @accessors;
	id canOnlyBeSubmittedOnce @accessors;
	id validationErrorMessages @accessors;
}

- (id) requiredPageResources {
	return [
        [WMPageResource javascript:"/wm-static/javascript/jquery/jquery-1.2.6.js"],
	    [WMPageResource javascript:"/wm-static/javascript/jquery/plugins/jquery.if.js"],
        [WMPageResource javascript:"/wm-static/javascript/WM/Component.js"],
        [WMPageResource javascript:"/wm-static/javascript/WM/FormComponent.js"],
        [WMPageResource javascript:"/wm-static/javascript/WM/Form.js"],
        [WMPageResource javascript:"/wm-static/javascript/WM/Validator.js"],
	];
}

- (id) init {
	[super init];
	[self setMethod:"POST"];
	return self;
}

- (id) formName {
	return [self name] || [self queryKeyNameForPageAndLoopContexts];
}

- (id) appendToResponse:(id)response inContext:(id)context {
	// every form needs to emit the context number so the responding
	// process knows if it has been called in order.
	[[self queryDictionaryAdditions] addObject:
				{ "NAME": "context-number",
				  "VALUE": [[[self context] session] contextNumber],
				}];
	return [super appendToResponse:response inContext:context];
}

// these are just synonyms to help you in bindings files:

- (void) setEnctype:(id)value {
	[self setEncType:value];
}

- (void) setIsMultipart:(id)value {
	if (value) {
		[self setEncType:"multipart/form-data"];
	} else {
		[self setEncType];
	}
}

- (void) setIsMultiPart:(id)value {
	[self setIsMultipart:value];
}

- (id) validationErrorMessagesArray {
	var h = [self validationErrorMessages];
	var msgs = [];
	for (var k in h) {
		var v = h[k];
		msgs.push({'key':k, 'value':v});
	}
	return msgs;
}

- (id) Bindings {
	var _bindings = [super Bindings];
	return UTIL.update(_bindings,
		{
		inheritsFrom: "WMURL",
		HIDDEN_KEY_VALUE: {
			type: "HiddenField",
			bindings: {
				name: 'aKeyValuePair.NAME',
				value: 'aKeyValuePair.VALUE',
			},
		},
		TAG_ATTRIBUTES: {
			type: "ATTRIBUTES",
		},
		CONTENT: {
			type: "CONTENT",
		},
		METHOD: {
			type: "STRING",
			value: 'method',
		},
		ENC_TYPE: {
			type: "STRING",
			value: 'encType',
		},
		HAS_ENC_TYPE: {
			type: "BOOLEAN",
			value: 'encType',
		},
		SHOULD_ENABLE_CLIENT_SIDE_SCRIPTING: {
			type: "BOOLEAN",
			value: 'shouldEnableClientSideScripting',
		},
		IS_FIRST_TIME_RENDERED: {
			type: "BOOLEAN",
			value: 'isFirstTimeRendered',
		},
		FORM_NAME: {
			type: "STRING",
			value: 'formName',
		},
		UNIQUE_ID: {
			type: "STRING",
			value: 'uniqueId',
		},
		JAVASCRIPT_ROOT: {
			type: "STRING",
			value: 'application.systemConfigurationValueForKey("JAVASCRIPT_ROOT")',
		},
		PARENT_BINDING_NAME: {
			type: "STRING",
			value: 'nestedBindingPath',
		},
		CAN_ONLY_BE_SUBMITTED_ONCE: {
			type: "BOOLEAN",
			value: 'canOnlyBeSubmittedOnce',
		},
		HAS_VALIDATION_ERROR_MESSAGES: {
			type: "BOOLEAN",
			//value: 'validationErrorMessages.keys.length',
			value: '"0"',
		},
		VALIDATION_ERROR_MESSAGES: {
			type: "LOOP",
			list: 'validationErrorMessagesArray',
			item: "aMessage",
		},
		A_VALIDATION_ERROR_MESSAGE_TEXT: {
			type: "STRING",
			value: 'aMessage.value',
		},
		A_VALIDATION_ERROR_MESSAGE_KEY: {
			type: "STRING",
			value: 'aMessage.key',
		},
	});
}

@end
