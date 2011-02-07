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

@import <Foundation/CPArray.j>

@implementation WMArray : CPArray

+ (WMArray) arrayFromObject:(id)object {
    if (object && object.isa && [object isKindOfClass:CPArray] && [object isKindOfClass:WMArray]) {
        return  [[WMArray alloc] initWithArray:object];
    }

    // not sure if this is sufficient to determine if the
    // object is actually a javascript array, but
    // whatevah
    var o = [WMArray new];
    if (!object) { return o }
    if (typeof object != "string" && typeof object.length == "number") {
        for (var i=0; i<object.length; i++) {
            [o addObject:object[i]];
        }
        return o;
    }

    [o addObject:object];
    return o;
}

+ (Boolean) isArray:(id)foo {
    if (!foo) { return false }
    if (typeof foo != "object") {
        return false;
    }
    if (foo.isa) {
        return ([foo isKindOfClass:CPArray] || [foo isKindOfClass:WMArray]);
    }
    if (typeof foo.length == "number") {
        return true;
    }
    return false;
}

@end

@import <WM/Category/WMKeyValueCoding.j>
