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
