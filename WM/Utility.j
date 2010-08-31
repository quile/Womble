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


var KP_RE = new RegExp('^[A-Za-z_\(\)]+[A-Za-z0-9_#\@\.\(\)\"]*$');
var KP_RE_PLUS = new RegExp('^[A-Za-z_\(\)]+[A-Za-z0-9_#\@]*[\(\.]+');

@implementation WMUtility : CPObject

+ (Boolean) expressionIsKeyPath:(id)expression {
    if (!expression) { return false }
    if ( expression.match(KP_RE) ) { return true }
    return expression.match(KP_RE_PLUS);
}

+ (id) evaluateExpression:(id)expression inComponent:(id)component context:(id)context {
    if (!component) { return nil }

    if ([self expressionIsKeyPath:expression]) {
        //[WMLog debug:"expression " + expression + " is key path"];
        return [component valueForKeyPath:expression];
    }

    // hack
    var foo = self;
    self = component;
    try {
        var rv = eval(expression);
        return rv;
    } catch (e) {
        [WMLog warning:"Expression (" + expression + ") evaluation failure: " + e];
    } finally {
        self = foo;
    }
    return expression;
}

@end
