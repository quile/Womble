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
@import <WM/Utility.j>
@import <WM/Log.j>

@implementation WMUtilityTest : OJTestCase

- (void) testBalanced {
    var data = {
        '{': 2,
        '(': 1,
        '"': 3
    };
    [self assertFalse:[WMUtility isBalanced:data]];
    data['('] = 0;
    data['{'] = 0;
    [self assertFalse:[WMUtility isBalanced:data]];
    [self assert:[WMUtility unBalanced:data] equals:'"'];

    data['"'] = 2;
    [self assertTrue:[WMUtility isBalanced:data]];
}

- (void) testDelimitedChunks {
    var data = "asterix and obelix) and dogmatix";
    var result = [WMUtility extractDelimitedChunkFrom:data terminatedBy:")"];
    [self assert:result equals:"asterix and obelix"];

    // nested
    var data = "tintin and (captain haddock) and calculus)";
    var result = [WMUtility extractDelimitedChunkFrom:data terminatedBy:")"];
    [self assert:result equals:"tintin and (captain haddock) and calculus"];

    // quotes?
    var data = '"xanadu", "kublai khan", stately({pleasuredome}), "decree"]'
    var result = [WMUtility extractDelimitedChunkFrom:data terminatedBy:"]"];
    [self assert:result equals:'"xanadu", "kublai khan", stately({pleasuredome}), "decree"'];
}

- (void) testKeyPathElements {
    // simple
    var keyPath = "chopin";
    var elements = [WMUtility keyPathElementsForPath:keyPath];
    [self assert:elements[0]['key'] equals:"chopin"];
    [self assert:elements.length equals:1];

    // double
    keyPath = "franz.liszt";
    var elements = [WMUtility keyPathElementsForPath:keyPath];
    [self assert:elements[0]['key'] equals:"franz"];
    [self assert:elements[1]['key'] equals:"liszt"];

    // simple with argument
    keyPath = "felix(mendelssohn)";
    var elements = [WMUtility keyPathElementsForPath:keyPath];
    [self assert:elements[0]['key'] equals:"felix"];
    [self assert:elements[0]['arguments'][0] equals:"mendelssohn"];

    // with whitespace and commas
    keyPath = "felix(mendelssohn, bartholdy )";
    var elements = [WMUtility keyPathElementsForPath:keyPath];
    [self assert:elements[0]['key'] equals:"felix"];
    [self assert:elements[0]['arguments'][0] equals:"mendelssohn"];
    [self assert:elements[0]['arguments'][1] equals:"bartholdy"];

    // multi with argument
    keyPath = "johann.sebastian(bach)";
    var elements = [WMUtility keyPathElementsForPath:keyPath];
    [self assert:elements[0]['key'] equals:"johann"];
    [self assert:elements[1]['key'] equals:"sebastian"];
    [self assert:elements[1]['arguments'][0] equals:"bach"];

    // multi with complex arguments
    keyPath = "johann(wolfgang).von('goethe')";
    var elements = [WMUtility keyPathElementsForPath:keyPath];
    [self assert:elements[0]['key'] equals:"johann"];
    [self assert:elements[1]['key'] equals:"von"];
    //[self assert:elements[0]['arguments'][0] equals:"wolfgang"];
    //[self assert:elements[1]['arguments'][0] equals:"'goethe'"];
}

@end
