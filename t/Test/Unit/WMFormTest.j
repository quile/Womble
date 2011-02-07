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
