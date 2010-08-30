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

@import <WM/Object.j>
@import <WM/Application.j>

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


+ alternateStylesheetNamed:(id)name {
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

- tag {
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

@end
