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
