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
