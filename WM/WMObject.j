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

@import <Foundation/CPObject.j>
@import <Foundation/CPKeyValueCoding.j>
@import <Foundation/CPException.j>

@implementation WMObject : CPObject
{
}

// TODO: consider using my own implementation of KVC, which is
// a bit smarter about many things, including being able
// to traverse arbitrary data structures, and to allow
// key paths with argument lists (like "foo.bar(banana, apple)")

//- (id)valueForUndefinedKey:(CPString)aKey {
//    // DANGER!? could this loop?
//    if (aKey.indexOf(".") != -1) {
//        return [self valueForKeyPath:aKey];
//    }
//    // what about FOO_BAR?
//}

- (void) subclassResponsibility {
    [CPException raise:@"You must override this method"];
}

@end

@import <WM/Category/WMKeyValueCoding.j>
