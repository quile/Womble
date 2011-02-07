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

@import "WMObject.j";

@implementation WMConfig : WMObject
{
}


var BUILD_VERSION = 1;

try {
    BUILD_VERSION = require("conf/BUILD_VERSION.conf");
} catch (e) {
    [[WMException initWithString:"Couldn't load build version; maybe you need run 'make javascript' for the framework"] raise];
}

DEFAULTS = {
    DEFAULT_ENTITY_CLASS: "WMEntityPersistent",
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

DEFAULTS = [WMDictionary initWithFoo:DEFAULTS];

try {
    APP_CONFIGURATION = require("conf/ACTIVE/WM.conf");
} catch (e) {
    [[WMException initWithString:"Failed to load WM.conf:"] raise];
}

[CONFIGURATION addEntriesFromDictionary:APP_CONFIGURATION];

@end
