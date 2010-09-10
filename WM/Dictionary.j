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

var QS = require("querystring")

@import <Foundation/CPDictionary.j>

@implementation WMDictionary : CPDictionary

+ (id) dictionaryFromQueryString:(id)string {
    return QS.parseQuery(string);
}

+ (id) dictionaryFromObject:(id)object {
    return [self newFromObject:object];
}

+ (id) newFromObject:(id)object {
    if (object.isa && ([object isKindOfClass:CPDictionary] || [object isKindOfClass:WMDictionary])) {
        return object;
    }

    if (typeof object != "string" && typeof object.length != "number") {
        var n = [WMDictionary new];
        var k;
        for (k in object) {
            [n setObject:object[k] forKey:k];
        }
        return n;
    }

    return nil;
}

@end
