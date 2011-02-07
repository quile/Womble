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

@import <Foundation/CPArray.j>
@import <WM/WMComponent.j>
@import <WM/WMLog.j>

var COMBINED_PAGE_RESOURCE_TAG = "<%_PAGE_RESOURCES_%>";
var CSS_PAGE_RESOURCE_TAG = "<%_CSS_PAGE_RESOURCES_%>";
var JS_PAGE_RESOURCE_TAG = "<%_JS_PAGE_RESOURCES_%>";

@implementation WMComponent (WMPageResourceHandling)

// -------------- "resource" management ------------
// this should return a list of "page" resources
// that this component requires.  For example,
// a component that needs a particular stylesheet
// should return
// [ [WMPageResource stylesheet:"/stylesheets/foo.css"] ]
//

- (CPArray) requiredPageResources {
	return [];
}

// TODO
// This is not exactly ideal, because this should live in the
// appendToResponse of a parent method, and all pages etc
// should inherit it and just "work".  However, until
// the inheritance hierarchy is cleaned up, we can't do that,
// mainly because of the caching pages, so instead this goop
// is buried in a convenience here that can be called from
// the appendToResponse() methods of the different subclasses of WMComponent.

- (void) addPageResourcesToResponse:(id)response inContext:(id)context {
	// cheezy hack
	if ([self isRootComponent]) {
		var content = [self _contentWithPageResourcesFromResponse:response];
		[response setContent:content];
	}
}

- (id) _contentWithPageResourcesFromResponse:(id)response {
	var content = [response content];
	var cssResources = [self htmlForPageResourcesOfType:'stylesheet' inResponse:response];
	var jsResources  = [self htmlForPageResourcesOfType:'javascript' inResponse:response];
	// replace the tag even if it's with nothing ...
	var allResources = cssResources + jsResources;
	content = content.replace(CSS_PAGE_RESOURCE_TAG, cssResources);
	content = content.replace(JS_PAGE_RESOURCE_TAG, jsResources);
	content = content.replace(COMBINED_PAGE_RESOURCE_TAG, allResources);
	[WMLog debug:" ^^^^^^^^^^^^^^^^ inserting resources into page ^^^^^^^^^^^^^^^ "];
	return content;
}

// This asks the context for all accumulated page resources
// and generates tags that pull them into the page.  This is
// a bit gnarly because generating HTML from here is bad,
// bit this stuff will change very infrequently.

- (id) htmlForPageResourcesOfType:(id)type inResponse:(id)response {
	var resources = [[response renderState] pageResources];
	if (!resources.length) { return "" }

	var filteredSet = [];
	for (var i=0; i<resources.length; i++) {
		var r = resources[i];
		if ([r type] == type) {
			filteredSet[filteredSet.length] = r;
		}
	}
	if (!filteredSet.length) { return "" }

	var content = "";
	for (var i=0; i<filteredSet.length; i++) {
		var r = filteredSet[i];
		content = content + [r tag] + "\n";
	}
	return content;
}

@end
