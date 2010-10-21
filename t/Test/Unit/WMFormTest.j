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
@import <WM/Component/Form.j>
@import <WM/Component/HiddenField.j>
@import <WM/Component/RadioButtonGroup.j>
@import <WM/Component/CheckBoxGroup.j>
@import <WM/Component/TextField.j>
@import <WM/Component/Text.j>
@import <WM/Component/HiddenField.j>
@import <WM/Component/PopUpMenu.j>
@import <WM/Component/ScrollingList.j>
@import <WM/Component/Selection.j>
@import <WM/Component/SubmitButton.j>

@import "../../Component/WMTest/Form.j"
@import "../../Application.j"

var application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation WMFormTest : OJTestCase

- (void) testInstantiation {
    var component = [WMForm new];
    [self assertNotNull:component message:"instantiated ok"];
}

- (void) testRender {
    var component = [WMForm new];
    [component setServer:"www.zig.zag"];
    [component setLanguage:"fr"];
    [component setTargetComponentName:"FooBar"];
    var content = [component render];
    [self assertTrue:content.match("http://www.zig.zag/WMTest/root/fr/FooBar/default")];
}

- (void) testElements {
    var component = [WMTestForm new];
    var content = [component render];
    [WMLog debug:content];
}

@end
