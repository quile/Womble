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

@import <WM/WMComponent.j>
@import <WM/WMPageResource.j>

@implementation WMTestBinding : WMComponent
{
    id allowsDirectAccess @accessors;
}

- (id) hovercraft {
    return "full of eels";
}

- (id) record {
    return "scratched";
}

- (id) Bindings {
    return {
        keypath_binding: {
            type: "STRING",
            value: keypath('hovercraft'),
        },
        kp_binding: {
            type: "STRING",
            value: kp('record'),
        },
        raw_binding: {
            type: "STRING",
            value: raw("tobacconist"),
        },
        objj_binding: {
            type: "STRING",
            value: objj("[[self hovercraft] uppercaseString]"),
        },
        js_binding: {
            type: "STRING",
            value: js("(function() { return 'eels' }).apply()"),
        },
    };
}

@end
