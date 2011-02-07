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
