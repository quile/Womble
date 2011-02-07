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

@import <OJUnit/OJTestCase.j>
@import <WM/WMUtility.j>
@import <WM/WMLog.j>

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
