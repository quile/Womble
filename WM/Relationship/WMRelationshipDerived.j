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

@import "WMRelationshipModelled.j"

@implementation WMRelationshipDerived : WMRelationshipModelled
{
    WMFetchSpecification fetchSpecification @accessors;
}

+ newFromFetchSpecification:(id)fs withName:(id)n {
    var d = [[self alloc] init];
    d._name = n;
    [d setFetchSpecification:fs];
    return d;
}

- targetEntity {
    return [[self fetchSpecification] entity];
}

- targetEntityClassDescription {
    return [[self fetchSpecification] entityClassDescription];
}

- type {
    return "TO_MANY";
}

/* These aren't defined because there's no actual
   relationship: that has to be applied via a
   separate qualifier
*/

- sourceAttribute {
    return null;
}

- targetAttribute {
    return null;
}

@end
