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

@import "../WMModel.j"
@import "../WMDB.j"
@import "../WMLog.j"

var OS = require("os");
var FILE = require("file");

@implementation WMDefaultApplication : WMApplication
{
}

- init {
    [super init]
    /* TODO:  This is a stop-gap solution until we make
       the whole DB interface OO.
    */
    //[WMLog debug:"Setting DB information"];
    [WMDB setDatabaseInformation:[self configurationValueForKey:"DB_LIST"]
                                :[self configurationValueForKey:"DB_CONFIG"]
                            ];
    var modelPath = [self configurationValueForKey:"DEFAULT_MODEL"];
    [WMLog debug:"Attempting to load default model " + modelPath];
    var mcp = FILE.path(modelPath);

    var modelClassName = [[self class] defaultModelClassName];
    try {
        var modelClass = objj_getClass(modelClassName);
        var m = [[modelClass alloc] initWithModelAtPath:mcp.canonical()];
        [WMModel setDefaultModel:m];
    } catch (e) {
        [WMLog error:e];
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
    if (![WMLog assert:[modules count] message:"Found at least one application module to initialise"]) {
        return
    }

//    foreach var module (@modules) {
//        eval "use module";
//        if ($@) {
//            /*WM::Log::error("Module failed to load: $@"); */
//            die "DIED Loading application module module: $@";
//        }
//        var m = [module new];
//        [self registerModule:m];
//    }
}

@end
