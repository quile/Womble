/* --------------------------------------------------------------------
 * IF - Web Framework and ORM heavily influenced by WebObjects & EOF
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

@import "../Model.j"
@import "../DB.j"
@import "../Log.j"

var OS = require("os");
var FILE = require("file");

@implementation IFDefaultApplication : IFApplication
{
}

- init {
    [super init]
	/* TODO:  This is a stop-gap solution until we make
	   the whole DB interface OO.
    */
	//[IFLog debug:"Setting DB information"];
	[IFDB setDatabaseInformation:[self configurationValueForKey:"DB_LIST"]
								:[self configurationValueForKey:"DB_CONFIG"]
                            ];
    var modelPath = [self configurationValueForKey:"DEFAULT_MODEL"];
	[IFLog debug:"Attempting to load default model " + modelPath];
    var mcp = FILE.path(modelPath);

	var modelClassName = [self defaultModelClassName];
    try {
        var modelClass = objj_getClass(modelClassName);
        var m = [[modelClass alloc] initWithModelAtPath:mcp.canonical()];
        [IFModel setDefaultModel:m];
    } catch (e) {
        [IFLog error:e];
        OS.exit(1);
    }

	/* Load up the application's modules and initialise them */
	[self loadModules];
	return self;
}

- defaultLanguage {
	if (!defaultLanguage) {
		defaultLanguage = [self configurationValueForKey:"DEFAULT_LANGUAGE"];
	}
	return defaultLanguage;
}

- defaultModule {
	return [[self configurationValueForKey:"DEFAULT_APPLICATION_MODULE"] instance];
}


+ cleanUpTransactionInContext:(id)context {
	/* perform your transaction cleanup here */
	[super cleanUpTransactionInContext:context];
}

- environmentIsProduction {
	var environment = [self configurationValueForKey:"ENVIRONMENT"];
	if (environment.match(/^PROD/)) { return true; }
	return false;
}

- loadModules {
	var modules = [self configurationValueForKey:"APPLICATION_MODULES"];
	if (![IFLog assert:[modules count] message:"Found at least one application module to initialise"]) {
        return
    }

//	foreach var module (@modules) {
//		eval "use module";
//		if ($@) {
//			/*IF::Log::error("Module failed to load: $@"); */
//			die "DIED Loading application module module: $@";
//		}
//		var m = [module new];
//		[self registerModule:m];
//	}
}

@end
