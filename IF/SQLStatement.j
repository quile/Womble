/* --------------------------------------------------------------------
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

/*
    Represents a SQL statement ready to be
    fired off to the DB
*/

@import "Object.j"

@implementation IFSQLStatement : IFObject
{
    id sql @accessors;
    id bindValues @accessors;
}

+ (IFSQLStatement) newWithSQL:(id)s andBindValues:(id)bvs {
    return [[super alloc] initWithSQL:s andBindValues:bvs];
}

- (IFSQLStatement) initWithSQL:(id)s andBindValues:(id)bvs {
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
