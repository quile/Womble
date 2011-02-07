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

@import <WM/WMObject.j>

var REQUEST = require("jack/request");

@implementation WMRequest : WMObject
{
    id _applicationName;
    id _request;

    id __formKeys;
    id __formDictionary;
}

+ (id) newFromRequest:(id)r {
    // TODO:kd - test r and init with the right kind of request
    var request = [[super new] initWithJackRequest:r];
    return request;
}

- (id) initWithEnv:(id)env {
    var jr = new REQUEST.Request(env);
    [self initWithJackRequest:jr];
    return self;
}

- (id) initWithJackRequest:(id)jr {
    _request = jr;
    return self;
}

- (id) applicationName {
    if (_applicationName) { return _applicationName }
    // TODO: where do we get the app name?  in mod_perl, it was
    // set automatically by mod_perl when the request was being routed.
    return _request.env['womble.application.name'] || 'WM';
}

- (void) setApplicationName:(id)name {
    _applicationName = name;
}

- (id) formKeys {
    if (!__formKeys) {
        __formKeys = [WMArray arrayFromObject:_p_keys(_request.params())];
    }
    return __formKeys;
}

- (id) formValueForKey:(id)key {
    return _request.params()[key];
}

// This is a bit ghetto
- (id) headerValueForKey:(id)key {
    return _request.env[key];
}

- (id) uri {
    return _request.pathInfo();
}

- (id) queryString {
    return _request.queryString();
}

@end
