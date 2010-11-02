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

@import <WM/WMObject.j>

var REQUEST = require("jack/request");

@implementation WMRequest : WMObject
{
    id _applicationName;
    id _request;

    id __formKeys;
    id __formDictionary;
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
    //return ENV['WM_APPLICATION_NAME'] || 'WM';
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
