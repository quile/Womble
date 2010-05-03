/* --------------------------------------------------------------------
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

@import "Object.j";

@implementation IFConfig : IFObject
{
}


var BUILD_VERSION = 1;

try {
    BUILD_VERSION = require("conf/BUILD_VERSION.conf");
} catch (e) {
    [[IFException initWithString:"Couldn't load build version; maybe you need run 'make javascript' for the framework"] raise];
}

DEFAULTS = {
	DEFAULT_ENTITY_CLASS: "IFEntityPersistent",
	DEFAULT_BATCH_SIZE: 30,
	DEFAULT_LANGUAGE: "en",
	DEFAULT_MODEL: "",  // TODO:  maybe come up with a better default for this?
	SEQUENCE_TABLE: "SEQUENCE",
	JAVASCRIPT_ROOT: "/javascript",
	/* these may get re-defined in the site-specific conf
	   so we want to load that last
    */
	SHOULD_CACHE_TEMPLATE_PATHS: 1,
	SHOULD_CACHE_TEMPLATES: 0,
	SHOULD_CACHE_BINDINGS: 0,
	BUILD_VERSION: BUILD_VERSION,
};

DEFAULTS = [IFDictionary initWithFoo:DEFAULTS];

try {
	APP_CONFIGURATION = require("conf/ACTIVE/IF.conf");
} catch (e) {
    [[IFException initWithString:"Failed to load IF.conf:"] raise];
}

[CONFIGURATION addEntriesFromDictionary:APP_CONFIGURATION];

@end
