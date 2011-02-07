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

@import <WM/WMComponent.j>
@import <WM/Component/WMURL.j>

@implementation WMHyperlink : WMURL
{
	id shouldIncludeSID @accessors;
	id onClickHandler @accessors;
	id title @accessors;
}

- (id) sessionId {
	if (![self shouldIncludeSID]) { return nil }
	return sessionId;
}

- (id) hasCompiledResponse {
	if ([self componentNameRelativeToSiteClassifier] == "Hyperlink") { return true }
	return false;
}

- (id) shouldSuppressQueryDictionaryKey:(id)key {
	if (key == [[self application] sessionIdKey] && ![self shouldIncludeSID]) { return true }
	return false;
}

// This has been unrolled to speed it up; do not be tempted to do this
// anywhere else!

- (id) appendToResponse:(id)response inContext:(id)context {
	if ([self hasCompiledResponse] && [self componentNameRelativeToSiteClassifier] == "Hyperlink") {
	    [[response renderState] addPageResources:[self requiredPageResources]];

		// asString is compiled response of IF::Component::URL
		var html = '<a href="'  + [self asString] +  '"';

		if ([self onClickHandler]) {
			html = html + ' onclick="' + [self onClickHandler] + '"';
		}

		if ([self title]) {
			html = html + ' title="' + [self title] + '"';
		}

		html = html + ' ' + [WMComponent TAG_ATTRIBUTE_MARKER] + ' >';
		html = html + [WMComponent COMPONENT_CONTENT_MARKER] + '</a>';

		[response setContent:html];
		return;
	} else {
		return [super appendToResponse:response inContext:context];
	}
}

- (id) url {
	return [super url] || [self tagAttributeForKey:"URL"];
}

- (id) title {
	title = title || [self tagAttributeForKey:"title"];
	return title;
}

@end
