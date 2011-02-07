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
@import "../../Component/WMTest/Home.j"
@import "../../Component/WMTest/Nested/Home.j"

var application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation WMComponentTest : OJTestCase

- (void) testInstantiation {
    var component = [WMTestHome new];
    [self assertNotNull:component message:"instantiated ok"];
}

- (void) testBasicRendering {
    var component = [WMTestHome new];
    var o = [component render];
    [self assertTrue:(o && o.match(/Jabberwock/)) message:"Rendered directly"];
}

- (void) testFancyRendering {
    var component = [WMTestHome new];
    var response = [component response];
    [component appendToResponse:response inContext:nil];
    [self assertTrue:[response content].match(/Jabberwock/) message:"Rendered via response"];
}

- (void) testDirectAccess {
    var component = [WMTestHome new];
    [component setAllowsDirectAccess:true];
    var o = [component render];
    [self assertTrue:o.match(/Zabzib/) message:"Direct access of properties working"];
}

- (void) testBindingNotFound {
    var component = [WMTestHome new];
    var o = [component render];
    [self assertTrue:o.match(/Binding quux not found/) message:"Binding not found message"];
}

- (void) testNestedComponents {
    var component = [WMTestHome new];
    var o = [component render];

    [self assertTrue:o.match('frumious') message:"Root's required resource appears"];
    [self assertTrue:o.match('slithy') message:"Subcomponent's required resource appears"];

    // check the subcomponent is rendered
    [self assertTrue:o.match(/Mimsy/) message:"Nested subcomponent rendered"];

    // this tests bindings in subcomponents
    [self assertTrue:o.match(/Bing!/) message:"Nested subcomponent bindings rendered"];

    // this tests that values are bound into subcomponents
    [self assertTrue:o.match(/Guanabana/) message:"Nested subcomponent bindings passed"];

    var component = [WMTestNestedHome new];
    var o = [component render];

    var re = new RegExp("The password is <strong>Ping!</strong>");
    [self assertTrue:o.match(re) message:"Doubly nested subcomponent rendered correctly"];
}

- (void) testBasicLanguageResolution {
    var component = [WMTestHome new];
    var o = [component renderWithParameters:{ language: "es" }];
    [self assertTrue:o.match(/Vamos/) message:"Nested subcomponent rendered in correct language"];
}

- (void) testWrappingComponents {
    var component = [WMTestHome new];
    var o = [component render];
    [self assertTrue:o.match(new RegExp("<b>This should be bold</b>")) message:"Wrapping component worked"];
}

@end
