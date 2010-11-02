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

@import <WM/WMComponent.j>
@import <WM/WMPageResource.j>

@import "Footer.j"

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
        //system_test: {
        //    type: "URL",
        //    bindings: {
        //        url: '"http://b3ta.com"',
        //    },
        //},
    };
}

@end
