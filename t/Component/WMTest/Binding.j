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

@import <WM/Component.j>
@import <WM/PageResource.j>

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
