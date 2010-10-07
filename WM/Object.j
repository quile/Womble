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

@import <Foundation/CPObject.j>
@import <Foundation/CPKeyValueCoding.j>
@import <Foundation/CPException.j>

@implementation WMObject : CPObject
{
}

// TODO: consider using my own implementation of KVC, which is
// a bit smarter about many things, including being able
// to traverse arbitrary data structures, and to allow
// key paths with argument lists (like "foo.bar(banana, apple)")

//- (id)valueForUndefinedKey:(CPString)aKey {
//    // DANGER!? could this loop?
//    if (aKey.indexOf(".") != -1) {
//        return [self valueForKeyPath:aKey];
//    }
//    // what about FOO_BAR?
//}

- (void) subclassResponsibility {
    [CPException raise:@"You must override this method"];
}

@end
