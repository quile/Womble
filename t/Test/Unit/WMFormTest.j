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
@import <WM/Component/WMForm.j>
@import <WM/Component/WMHiddenField.j>
@import <WM/Component/WMRadioButtonGroup.j>
@import <WM/Component/WMCheckBoxGroup.j>
@import <WM/Component/WMTextField.j>
@import <WM/Component/WMText.j>
@import <WM/Component/WMHiddenField.j>
@import <WM/Component/WMPopUpMenu.j>
@import <WM/Component/WMScrollingList.j>
@import <WM/Component/WMSelection.j>
@import <WM/Component/WMSubmitButton.j>

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

- (void) testTextField {
    var component = [WMTestForm new];
    var content = [component render];
    [self assertTrue:content.match('banana="mango"')];
    [self assertTrue:content.match('rows="5"')];
    //[WMLog debug:content];
}

@end
