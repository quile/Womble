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
@import <WM/Classes.j>
@import <WM/Component/URL.j>
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

@end
