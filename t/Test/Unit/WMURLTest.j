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
@import <WM/WMClasses.j>
@import <WM/Component/WMURL.j>
@import "../../Application.j"

var application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation WMURLTest : OJTestCase

- (void) testInstantiation {
    var component = [WMURL new];
    [self assertNotNull:component message:"instantiated ok"];
}

- (void) testRender {
    var component = [WMURL new];
    [component setServer:"www.zig.zag"];
    [component setLanguage:"fr"];
    [component setTargetComponentName:"FooBar"];
    var content = [component render];
    [self assertTrue:content.match("http://www.zig.zag/WMTest/root/fr/FooBar/default")];
}

- (void) testBasicQueryString {
    var component = [WMURL new];
    [component setServer:"mango.goo"];
    [component setLanguage:"es"];
    [component setTargetComponentName:"BazBoo"];
    [component setQueryString:"vanilla=ice&mc=hammer"];
    var content = [component render];
    [self assertTrue:content.match("http://mango.goo/WMTest/root/es/BazBoo/default")];
    [self assertTrue:content.match("vanilla=ice")];
    [self assertTrue:content.match("mc=hammer")];
}

// TODO: lots of other tests...

@end
