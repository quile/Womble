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

/*==================================== */
@import "WMObject.j"
@import "WMModel.j"
@import "WMArray.j"
@import "WMDictionary.j"
@import "WMLog.j"
@import "Helpers.js"
@import <Foundation/CPKeyValueCoding.j>
/*==================================== */


@implementation WMEntity : WMObject
{
    id entityClassName @accessors;
}

+ newFromDictionary:(id)d {
    var e = [self new];
    [e initWithDictionary:d];
    return e;
}

- init {
    [super init];
    [self setEntityClassName:self.isa];
    return self;
}

- initWithDictionary:(id)d {
    [self init];
    var keys = _p_keys(d);
    for (var i=0; i < _p_length(keys); i++) {
        var key = _p_objectAtIndex(keys, i);
        var value = _p_objectForKey(d, key);
        [self setValue:value forKey:key];
    }
    return self;
}

/*----- */

/* stringification for use in admin tools and elsewhere
    Overload one or the other or be happy with the default
    behaviour
*/

/*
- summaryAttributes {
    return ['title', 'name'];
}
*/

/*
- asString:(id)separator {
    separator ||= ', ';
    if (var summaryAttributes = [self summaryAttributes]) {
        var rawAttrs = map {[self valueForKey:_]} @summaryAttributes;
        var attrs = [];
        foreach var a (rawAttrs) {
            push @attrs, a if a;
        }
        var str = join(', ', @attrs);
        return str if str;
    }
    return scalar self;
}
*/

@end
