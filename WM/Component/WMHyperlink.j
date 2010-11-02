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
