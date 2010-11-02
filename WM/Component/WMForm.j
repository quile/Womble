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

@import <WM/Component/WMHyperlink.j>
@import <WM/WMPageResource.j>

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
	return UTIL.update(_bindings, {
		hidden_key_value: {
			type: "HiddenField",
			bindings: {
				name: objj('[self aKeyValuePair].NAME'),
				value: objj('[self aKeyValuePair].VALUE'),
			},
		},
		tag_attributes: {
			type: "ATTRIBUTES",
		},
		content: {
			type: "CONTENT",
		},
		method: {
			type: "STRING",
			value: 'method',
		},
		enc_type: {
			type: "STRING",
			value: 'encType',
		},
		has_enc_type: {
			type: "BOOLEAN",
			value: 'encType',
		},
		should_enable_client_side_scripting: {
			type: "BOOLEAN",
			value: 'shouldEnableClientSideScripting',
		},
		is_first_time_rendered: {
			type: "BOOLEAN",
			value: 'isFirstTimeRendered',
		},
		form_name: {
			type: "STRING",
			value: 'formName',
		},
		unique_id: {
			type: "STRING",
			value: 'uniqueId',
		},
		javascript_root: {
			type: "STRING",
			value: 'application.systemConfigurationValueForKey("JAVASCRIPT_ROOT")',
		},
		parent_binding_name: {
			type: "STRING",
			value: 'nestedBindingPath',
		},
		can_only_be_submitted_once: {
			type: "BOOLEAN",
			value: 'canOnlyBeSubmittedOnce',
		},
		has_validation_error_messages: {
			type: "BOOLEAN",
			//value: 'validationErrorMessages.keys.length',
			value: '"0"',
		},
		validation_error_messages: {
			type: "LOOP",
			list: 'validationErrorMessagesArray',
			item: "aMessage",
		},
		a_validation_error_message_text: {
			type: "STRING",
			value: 'aMessage.value',
		},
		a_validation_error_message_key: {
			type: "STRING",
			value: 'aMessage.key',
		},
	});
}

@end
