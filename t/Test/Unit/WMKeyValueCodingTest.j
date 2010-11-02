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
@import <WM/WMObject.j>
@import <WM/WMLog.j>
@import <WM/Category/WMKeyValueCoding.j>

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

- (id) _s:(id)value {
    return value.toUpperCase();
}

- (id) donne {
    return {
        "john": 'jonny',
        "bruce": 'brucey'
    };
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

    [self assert:[obj valueForKey:"_s('donne')"] equals:"DONNE"];
    [self assert:[obj valueForKey:"donne.john"] equals:"jonny"];
    [self assert:[obj valueForKey:"_s(donne.john)"] equals:"JONNY"];
}

- (void) testDictionary {
    var d = [CPDictionary new];
    [d setObject:[CPDictionary new] forKey:"shelley"];
    [[d objectForKey:"shelley"] setObject:"percy" forKey:"bysshe"];
    [self assert:[d valueForKey:"shelley.bysshe"] equals:"percy"];
}

- (void) testArray {
    var a = [];
    a[0] = [CPDictionary dictionaryWithJSObject:{ 'wordsworth': 'william', 'keats': ['phil', 'bruce', 'andy', 'john'] }];
    a[1] = ["samuel", "pepys", [ 1633, 1703 ]];

    [self assert:[a valueForKey:"@0.wordsworth"] equals:"william"];
    [self assert:[a valueForKey:"@0.keats.@3"] equals:"john"];
    [self assert:[a valueForKey:"@1.@2.@0"] equals:1633];
    [self assert:[a valueForKey:"@0.keats.#"] equals:4];
    [self assert:[a valueForKey:"@1.@2.#"] equals:2];
}

@end
