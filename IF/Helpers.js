/* --------------------------------------------------------------------
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


// Goop in here is just to help with the perl -> js conversion
// and make my life a whole lot easier.  The general idea is
// to use this during the port and then punt it when things
// are "working".

var UTIL = require("util");

_p_length = function(thing) {
    if (!thing) { return nil }
    if (thing.isa) {
        return objj_msgSend(thing, "count");
    }

    return thing.length;
}

_p_keys = function(thing) {
    // if this is an objj object, send it an allKeys message
    if (!thing) { return [] }
    if (thing.isa) {
        return objj_msgSend(thing, "allKeys");
    }
    return UTIL.keys(thing);
}

_p_push = function(a, thing) {
    if (!a) { return }
    if (a.isa) {
        return objj_msgSend(a, "addObject:", thing);
    }
    a[a.length] = thing;
}

_p_objectAtIndex = function(a, index) {
    if (!a) { return nil }
    if (a.isa) {
        return objj_msgSend(a, "objectAtIndex:", index);
    }
    return a[index];
}

_p_setObjectAtIndex = function(a, value, index) {
    if (!a) { return }
    if (a.isa) {
        objj_msgSend(a, "replaceObjectAtIndex:withObject:", index, value);
    }
    a[index] = value;
}

_p_valueForKey = function(d, key) {
    if (!d) { return }
    if (d.isa) {
        return objj_msgSend(d, "valueForKey:", key);
    }
    return d[key];
}

_p_setValueForKey = function(d, value, key) {
    if (!d) { return }
    if (d.isa) {
        return objj_msgSend(d, "setValue:forKey:", value, key);
    }
    d[key] = value;
}

_p_isArray = function(a) {
    if (!a) { return false }
    if (a.isa && (a.isa == "CPArray" || a.isa == "IFArray")) {
        return true;
    }
    if (typeof a != "string" && typeof a.length == "number") {
        return true;
    }
    return false;
}

_p_setTrace = "var oj=require('objective-j');var R=require('readline');while(true){try{system.stdout.write('if> ').flush();var line=R.readline();if (line=='q'){break;}var r=eval(line);if (r!==undefined)print(r);}catch(e){print(e);}}";
