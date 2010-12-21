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

@import <WM/WMResponse.j>

@implementation WMException : WMResponse
{
    id _name @accessors(property=name);
    id _reason @accessors(property=reason);
    id _userInfo @accessors(property=userInfo);
}

// for now, just make it quack like a CPException
+ (WMException) raise:(id)name reason:(id)reason {
    [self raise:name reason:reason userInfo:nil];
}

+ (WMException) raise:(id)name reason:(id)reason userInfo:(id)userInfo {
    [[[super alloc] initWithName:name reason:reason userInfo:userInfo] raise];
}

- (id) initWithName:(id)name reason:(id)reason {
    return [self initWithName:name reason:reason userInfo:nil];
}

- (id) initWithName:(id)name reason:(id)reason userInfo:(id)userInfo {
    [self init];
    _name = name;
    _reason = reason;
    _userInfo = userInfo;
    return self;
}

- (void) raise {
    throw self;
}

- (void) body {
    var soFar = [self contentList];
    return soFar.concat(_reason);
}
    
@end

@implementation WMNotFound : WMException

- (id) init {
    [super init];
    _status = 404;
    _contentList = [ "Ooops! Not found" ];
    return self;
}

@end

@implementation WMBadRequest : WMException

- (id) init {
    [super init];
    _status = 400;
    _contentList = [ "Ooops! Bad Request" ];
    return self;
}

@end

@implementation WMInternalServerError : WMException

- (id) init {
    [super init];
    _status = 500;
    _contentList = [ "Ooops! Internal Server Error" ];
    return self;
}
@end
