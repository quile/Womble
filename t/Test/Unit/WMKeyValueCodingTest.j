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

@import <OJUnit/OJTestCase.j>
@import <WM/Object.j>
@import <WM/Log.j>
@import <WM/Category/KeyValueCoding.j>

@implementation _WMTestThing : WMObject
{
    id shakespeare @accessors;
    id bacon;
}

- (id) marlowe {
    return "christopher";
}

- (id) chaucer:(id)value {
    if (value == "geoffrey") { return "canterbury" }
    return "tales";
}

- (id) bacon {
    return bacon;
}

- (void) setBacon:(id)value {
    bacon = value;
}

@end

@implementation WMKeyValueCodingTest : OJTestCase
{
    id obj @accessors;
}

- (void) setUp {
    obj = [_WMTestThing new];
    [obj setValue:"william" forKey:"shakespeare"];
}

- (void) testObjectProperties {
    [obj setBacon:"francis"];
    [self assert:[obj valueForKey:"shakespeare"] equals:"william"];
    [self assert:[obj valueForKey:"marlowe"] equals:"christopher"];
    [self assert:[obj valueForKey:"bacon"] equals:"francis"];
}

- (void) testDictionary {
    d = [CPDictionary new];
    [d setObject:[CPDictionary new] forKey:"johnson"];
    [[d objectForKey:"johnson"] setObject:"ben" forKey:"ben"];
    [self assert:[d valueForKey:"johnson.ben"] equals:"ben"];
}

@end
