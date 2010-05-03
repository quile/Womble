/* --------------------------------------------------------------------
 * IF - Web Framework and ORM heavily influenced by WebObjects & EOF
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

/*==================================== */
@import "Object.j"
@import "Model.j"
@import "Array.j"
@import "Dictionary.j"
@import "Log.j"
@import "Helpers.js"
@import <Foundation/CPKeyValueCoding.j>
/*==================================== */


@implementation IFEntity : IFObject
{
    id entityClassName @accessors;
}

+ newFromDictionary:(id)d {
    [IFLog dump:d];
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
    [IFLog dump:keys];
    for (var i=0; i < _p_length(keys); i++) {
        var key = _p_objectAtIndex(keys, i);
        [self setValue:_p_valueForKey(d, key) forKey:key];
    }
    return self;
}

- awakeFromInflation {
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
