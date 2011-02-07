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
