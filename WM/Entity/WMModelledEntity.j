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

@import <Foundation/CPKeyValueCoding.j>
@import "WMPersistent.j"

@implementation WMModelledEntity : WMPersistentEntity {

// TODO: how do I dynamically alter the inheritance
// tree?  Easy in perl, not sure about objj!

/* Dealing with the Chicken-Egg problem */
/*
+ import:(id)c {
    var modelClass = c;
    modelClass =~ /( + *)::( + *)$/;
    modelClass = 1 + "::Model::_" + 2;
    no strict 'refs';
    var i = \@{c + "::ISA"};
    if (i && scalar @i > 0 && i.0 == modelClass) {
        WMLog.debug("Not pushing model class onto ISA because it's already there");
        return;
    }
    // add model class to the mix
    eval "use modelClass;";

    unless ($@) {
        unshift @i, modelClass;
    } else {
        eval "use WMEntityPersistent;";
        unshift @i, "WMEntityPersistent";
    }
}
*/

@end
