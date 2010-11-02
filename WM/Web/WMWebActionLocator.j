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

@import <Foundation/CPObject.j>
@import <WM/WMUtility.j>

var ACTION_REGEXP = new RegExp("^/([A-Z0-9]+)/([A-Z0-9]+)/([A-Z0-9-]+)/(..)/([[A-Z0-9\.-]+)$", "i");

@implementation WMWebActionLocator : CPObject
{
	id urlRoot @accessors;
	id siteClassifierName @accessors;
	id language @accessors;
	id targetComponentName @accessors;
	id directAction @accessors;
	id queryDictionary @accessors;
}

+ (id) newFromString:(id)string {
	var match = string.match(ACTION_REGEXP);
	if (!match) {
		[CPException raise:@"CPException" reason:"Couldn't parse action location " + string];
	}
	var urlRoot = match[1];
	var site = match[2];
	var lang = match[3];
	var component = match[4];
	var action = match[5];
	if (!action) { return nil }  // super weird dodgy line?
	var self = [super new];
	[self setDirectAction:action];
	[self setTargetComponentName:component];
	[self setLanguage:lang];
	[self setSiteClassifierName:site];
	[self setUrlRoot:urlRoot];
	return self;
}

- (id) asAction {
	return [urlRoot, siteClassifierName, language, targetComponentName, directAction].join("/");
}

@end
