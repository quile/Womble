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
var objj_ = require("objective-j")

escapeDoubleQuotes = function(string) {
	string = string.replace(new RegExp('"', "g"), '\"');
	return string;
}
// types for specifying arguments in bindings

keypath = function(kp) { return kp; }
kp = function(kp) { return keypath(kp); }

raw = function(r) {
    return '"' + escapeDoubleQuotes(r) + '"';
}

objj = function(c) {
    code = objj_.preprocess(c)._code;
    // TODO: check for errors
    return function(self, context) { return eval(code) }
}
js = function(c) {
    return function(self, context) { return eval(c); }
}
