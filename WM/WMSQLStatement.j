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

/*
    Represents a SQL statement ready to be
    fired off to the DB
*/

@import "WMObject.j"

@implementation WMSQLStatement : WMObject
{
    id sql @accessors;
    id bindValues @accessors;
}

+ (WMSQLStatement) newWithSQL:(id)s andBindValues:(id)bvs {
    return [[super alloc] initWithSQL:s andBindValues:bvs];
}

- (WMSQLStatement) initWithSQL:(id)s andBindValues:(id)bvs {
    [self setSql:s];
    [self setBindValues:bvs];
    return self;
}

- (CPString) description {
    var d = "[" + sql + "]";
    if ([bindValues count] > 0) {
        d += " (" + [bindValues componentsJoinedByString:", "] + ")";
    }
    return d;
}

@end
