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

@import "WMObject.j"
@import "WMApplication.j"

// FIXME: make this a config variable
var DEFAULT_JQUERY_VERSION = "1.2.6";

@implementation WMPageResource : WMObject
{
	id location @accessors;
	id domId @accessors;
	id mimeType @accessors;
	id type @accessors;
	id firstRequest @accessors;
	id title @accessors;
	id media @accessors;
}

+ (WMPageResource) stylesheet:(id)location {
	return [self stylesheet:location withDomId:nil];
}

+ (WMPageResource) stylesheet:(id)location withDomId:(id)domId {
	var value = [self new];
	[value setLocation:location];
	[value setDomId:domId];
	[value setMimeType:"text/css"];
	[value setType:"stylesheet"];
	return value;
}

+ javascript:(id)location {
	var value = [self new];
    [value setLocation:location];

    if ([[WMApplication defaultApplication] environmentIsProduction]) {
    	if (location.match(/WM/)) {
    	    [value setLocation:"/wm-static/javascript/wm.js"];
        } else if (location.match(/jquery.(\d\.\d\.\d).?js/)) {
            var version = 1 || DEFAULT_JQUERY_VERSION;
            [value setLocation:"http://ajax.googleapis.com/ajax/libs/jquery/" + version + "/jquery.min.js"];
        }
    }

	[value setMimeType:"text/javascript"];
	[value setType:"javascript"];
	return value;
}


+ (WMPageResource) alternateStylesheetNamed:(id)name {
	var value = [self new];
	[value setLocation:location, "location"];
	[value setTitle:name];
	[value setMimeType:"text/css" :"mimeType"];
	[value setType:"alternate stylesheet", "type"];
	return value;
}

- (id) title {
	return title || "";
}

// ------- this generates the tag to pull this resource in -------

- (id) tag {
	var libVersion = [WMApplication systemConfigurationValueForKey:"BUILD_VERSION"];

	if ([self type] == "javascript") {
		return '<script type="' + [self mimeType] + '" src="' + [self location] + '?v=' + libVersion + '"></script>';
	} else if ([self type] == "stylesheet" || [self type] == "alternate stylesheet") {
		var media = [self media] || "screen, print";
		var link = '<link rel="' + [self type] + '" type="' + [self mimeType] + '" href="' + [self location] + '?v=' + libVersion + '" media="' + media + '" title="' + [self title] + '"';
		if ([self domId]) { link = link + ' id="' + [self domId] + '" ' }
		link = link + ' />';
		return link;
	}
	return "<!-- unknown resource type: " + [self type] + " location: " + [self location] + " - ";
}

- (id) description {
	return [self tag];
}

@end
