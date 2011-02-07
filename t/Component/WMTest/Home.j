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

@import "Footer.j"
@import "Bold.j"

@implementation WMTestHome : WMComponent
{
    id allowsDirectAccess @accessors;
}

// testing page resources
- (id) requiredPageResources {
    return [
        [WMPageResource javascript:"/frumious/jubjub.js"],
    ]
}

- (id) zibzab { return "Zabzib!" }
- (id) foo {
    return [WMDictionary dictionaryWithJSObject:{
        bar: "Fascination!",
        baz: {
            banana: "mango",
        },
    }];
}

- (id) idol {
    return [WMDictionary dictionaryWithJSObject:{
            tosser: "Simon Cowell",
            nice: "Paula Abdul",
            funny: "Ryan Seacrest",
            cool: "Randy Jackson",
        }];
}

- (id) goop {
    return "YAK!";
}

+ (CPDictionary) Bindings {
    return {
        header: {
            type: "STRING",
            value: '"Jabberwock"',
        },
        footer: {
            type: "WMTestFooter",
            bindings: {
                someString: '"Guanabana"',
            },
        },
        bold: {
            type: "WMTestBold",
        },
        //system_test: {
        //    type: "URL",
        //    bindings: {
        //        url: '"http://b3ta.com"',
        //    },
        //},
    };
}

@end
