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
};

_p_keys = function(thing) {
    // if this is an objj object, send it an allKeys message
    if (!thing) { return [] }
    if (thing.isa) {
        return objj_msgSend(thing, "allKeys");
    }
    return UTIL.keys(thing);
};

_p_values = function(thing) {
    // if this is an objj object, send it an allKeys message
    if (!thing) { return [] }
    if (thing.isa) {
        return objj_msgSend(thing, "allValues");
    }
    return UTIL.values(thing);
};

_p_push = function(a, thing) {
    if (!a) { return }
    if (a.isa) {
        return objj_msgSend(a, "addObject:", thing);
    }
    a[a.length] = thing;
};

_p_objectAtIndex = function(a, index) {
    if (!a) { return nil }
    if (a.isa) {
        return objj_msgSend(a, "objectAtIndex:", index);
    }
    return a[index];
};

_p_setObjectAtIndex = function(a, value, index) {
    if (!a) { return }
    if (a.isa) {
        objj_msgSend(a, "replaceObjectAtIndex:withObject:", index, value);
    }
    a[index] = value;
};

_p_objectForKey = function(d, key) {
    if (!d) { return }
    if (d.isa) {
        return objj_msgSend(d, "objectForKey:", key);
    }
    return d[key];
};

_p_valueForKey = function(d, key) {
    if (!d) { return }
    if (d.isa) {
        return objj_msgSend(d, "valueForKey:", key);
    }
    return d[key];
};

_p_setValueForKey = function(d, value, key) {
    if (!d) { return }
    if (d.isa) {
        return objj_msgSend(d, "setValue:forKey:", value, key);
    }
    d[key] = value;
};

_p_isArray = function(a) {
    if (!a) { return false }
    if (a.isa && (a.isa == "CPArray" || a.isa == "WMArray")) {
        return true;
    }
    if (typeof a != "string" && typeof a.length == "number") {
        return true;
    }
    return false;
};

_p_isHash = function(a) {
    // cheesy
    if (!a) { return false }
    if (a.isa) {
        if (a.isa == "CPDictionary") {
            return true;
        } else {
            return false;
        }
    }// else {
    //    return false;
    //}
    return typeof a == "object";
}

_p_2_split = function(re, st) {
    var bits = st.split(re);
    var first = bits.shift();
    if (bits.length > 0) {
        st = st.replace(first, "");
        var second = st.substring(st.indexOf(bits.shift())) || "";
        return [first, second];
    }
    if (first == "") { return [] }
    return [first];
};

_p_lcfirst = function(str) {
    return str.substr(0, 1).toLowerCase() + str.substr(1, str.length);
};

_p_ucfirst = function(str) {
    return str.substr(0, 1).toUpperCase() + str.substr(1, str.length);
};

_p_niceName = function(name) {
	if (name.match(/^[A-Z0-9_]+$/)) {
        return _p_lcfirst(name.split("_").map(function (_u) { return _p_ucfirst(_u.toLowerCase()) }).join(""));
	}
	return name;
};

_p_quotemeta = function(str) {
    return str.replace( /([^A-Za-z0-9])/g , "\\$1" );
}

_p_trim = function(str) {
    return str.replace(/^\s+/, "").replace(/\s+$/, "");
}

_p_keyNameFromNiceName = function(niceName) {
	var pieces = niceName.split(/([A-Z0-9])/);
	var uppercasePieces = [];

	for (var i=0; i<pieces.length; i++) {
		if (pieces[i] == "") { continue }
		if (pieces[i].match(/^[a-z0-9]$/)) {
			uppercasePieces.push(pieces[i].toUpperCase());
		} else if (pieces[i].match(/^[A-Z0-9]$/)) {
			// either it's an acronym, a single char or
			// a first char

			if (pieces[i+1] != "") {
				uppercasePieces.push((pieces[i] + pieces[i+1]).toUpperCase());
				i++;
			} else {
				var j = i;
				// acronyms
				var acronym = "";
				while (pieces[i+1] == "" && i < pieces.length) {
					acronym = acronym + pieces[i];
					i+=2;
				}
				uppercasePieces.push(acronym);
                if (i >= pieces.length) { break }
				i--;
			}
		} else {
			uppercasePieces.push(pieces[i].toUpperCase());
		}
	}
	var keyName = uppercasePieces.join("_");
	return keyName;
};

// eval(_p_setTrace) lets you execute javascript in the current context
// of wherever your eval is.  Useful for checking values of vars and stuff.
_p_setTrace = "var oj=require('objective-j');var R=require('readline');while(true){try{system.stdout.write('wm> ').flush();var line=R.readline();if (line=='q'){break;}var r=eval(line);if (r!==undefined)print(r);}catch(e){print(e);}}";
