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
@import "../../Component/WMTest/Binding.j"

var application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation WMBindingTest : OJTestCase
{
    id component;
}

- (void) setUp {
    component = [WMTestBinding new];
    context = [WMContext emptyContext];
}

- (id) evaluateBinding:(id)n {
    return [component evaluateBinding:[component bindingForKey:n] inContext:context];
}

- (void) testStrings {
    var value = [self evaluateBinding:"keypath_binding"];
    [self assert:value equals:"full of eels"];

    var value = [self evaluateBinding:"kp_binding"];
    [self assert:value equals:"scratched"];
}

- (void) testRaw {
    var value = [self evaluateBinding:"raw_binding"];
    [self assert:value equals:"tobacconist"];
}

- (void) testEval {
    var value = [self evaluateBinding:"objj_binding"];
    [self assert:value equals:"FULL OF EELS"];

    var value = [self evaluateBinding:"js_binding"];
    [self assert:value equals:"eels"];
}

@end
