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
@import <Foundation/Foundation.j>
@import <WM/Application.j>
@import "../../Application.j"
@import <WM/Component/URL.j>

var application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation WMBundleTest : OJTestCase
{
}

- (void) testBundle {
    var componentBundle = [CPBundle bundleForClass:objj_getClass("WMURL")];
    [self assertTrue:[componentBundle bundlePath].match(/WM\/Component\/$/) message:"Located system component bundle"];

    var frameworkBundle = [CPBundle bundleForClass:objj_getClass("WMApplication")];
    [self assertTrue:[frameworkBundle bundlePath].match(/WM\/$/) message:"Located framework bundle"];
}

- (void) testResources {
    var componentBundle = [CPBundle bundleForClass:objj_getClass("WMURL")];
    [self assertTrue:[componentBundle bundlePath].match(/WM\/Component\/$/) message:"Located system component bundle"];

    // FIXME:kd - this assumes the implementation of CPBundle will always look in Resources/, which is probably a bit bogus.
    var templatePath = [componentBundle pathForResource:"templates/en/Foo.html"];
    [self assertTrue:templatePath.match(_p_quotemeta([componentBundle bundlePath] + "Resources/templates/en/Foo.html"))];
}

@end
