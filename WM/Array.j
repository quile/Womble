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

@import <WM/Category/KeyValueCoding.j>
