/* --------------------------------------------------------------------
 * IF - Web Framework and ORM heavily influenced by WebObjects & EOF
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


/*==================================
   This class is used to accumulate
   and output logging information,
   mostly used for debugging.
  ==================================
*/
var sys = require("system");

@import "Object.j"
@import "LogMessage.j";
@import "Array.j";

/* Message codes: */
var CODE_HEADER     = 0;
var CODE_DATABASE	= 1;
var CODE_DEBUG    	= 2;
var CODE_APACHE 	= 4;
var CODE_INFO 		= 8;
var CODE_WARNING	= 16;
var CODE_ERROR 		= 32;
var CODE_CODE       = 64;
var CODE_STRUCTURE  = 128;
var CODE_QUERY_DICTIONARY = 256;
var CODE_ASSERTION  = 512;

var MESSAGE_TYPES = {
    0x001: "DATABASE",
    0x002: "DEBUG",
    0x004: "APACHE",
    0x008: "INFO",
    0x010: "WARNING",
    0x020: "ERROR",
    0x040: "CODE",
    0x080: "PAGE",
    0x100: "QUERY_DICTIONARY",
	0x200: "ASSERTION",
};

var MESSAGE_COLOURS = {
    CODE_HEADER   : ["#aaaacc", "#000020" ],
    CODE_DATABASE : ["#cccccc", "#000000" ],
    CODE_DEBUG    : ["#ffff60", "#000000" ],
    CODE_APACHE   : ["#60ffff", "#000000" ],
    CODE_INFO     : ["#ff60ff", "#ffffff" ],
    CODE_WARNING  : ["#ffff00", "#ff0000" ],
    CODE_ERROR    : ["#ff0000", "#ffff00" ],
    CODE_CODE     : ["#000000", "#ffffff" ],
    CODE_STRUCTURE: ["#3030ff", "#ffffff" ],
    CODE_QUERY_DICTIONARY: ["#004000", "#ffffff" ],
	CODE_ASSERTION: ["#00ff00", "#ffff00"],
};

/* This is a static class */

var LOG_MASK = 0xffff;
var _pageStructureDepth = 0;

/* This will be filled per web transaction but will be flushed
   at the beginning of each one
*/
var MESSAGE_BUFFER = [IFArray new];
var START_TIME = 0;


@implementation IFLog : IFObject

+ setLogMask:aMask {
	LOG_MASK = aMask;
}

+ logMask {
	return LOG_MASK;
}

+ addMessage:(id)message {
	/* print it out if the log is set or message is an error */
	if (LOG_MASK & [message type] || [message type] == CODE_ERROR) {
		//sys.print([message time] + " " + MESSAGE_TYPES[[message type]] + " " + [message content] + "\n");
        sys.stderr.print([message description]);

		/* log it into the buffer */
        // TODO revisit this for offline code
		[MESSAGE_BUFFER addObject:message];
	}
}

+ incrementPageStructureDepth {
	_pageStructureDepth++;
}

+ decrementPageStructureDepth {
	_pageStructureDepth--;
}

+ (id) messageTypeStringForType:(id)aType {
    return MESSAGE_TYPES[aType];
}

+ startLoggingTransaction {
	START_TIME = [CPDate date];
	[IFLog clearMessageBuffer];
	[IFLog addMessage:
        [IFLogMessage newWithType:CODE_INFO andMessage:"======================================="]];
}

+ endLoggingTransaction {
	var elapsedTime = [CPDate timeIntervalSinceDate:date];
	[IFLog addMessage:
        [IFLogMessage newWithType:CODE_INFO addMessage:"Total elapsed time: " + elapsedTime + " seconds"]];
	[IFLog addMessage:
        [IFLogMessage newWithType:CODE_INFO addMessage:"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"]];
}

+ messageBuffer {
	return MESSAGE_BUFFER;
}

+ clearMessageBuffer {
	[MESSAGE_BUFFER removeAllObjects];
}

+ htmlOpenTable:(id)dumpMask {
	return "<table width=100% cellpadding=1 cellspacing=0 border=0>\n" +
						"<tr><td bgcolor=#000000>\n" +
					    "<table width=100% cellpadding=2 cellspacing=1 border=0>\n";
}

+ htmlCloseTable:(id)dumpMask {
	return "</table>\n</td></tr>\n</table>";
}

+ htmlColumnHeaders:(id)dumpMask {
	var messageTable = "<tr><td align=center bgcolor=#333300><font face=Verdana size=2 color=#ffffff>TIME/TYPE</font></TD>";
	messageTable = messageTable + "<TD align=center bgcolor=#333300><font face=Verdana size=2 color=#ffffff>MESSAGE</font></TD></TR>";
	return messageTable;
}

+ htmlRowFromLogEvent:(id)message dumpMask:(id)dumpMask {
    var mt = [message type];
	var rowColor = MESSAGE_COLOURS[mt][0];
	var textColor = MESSAGE_COLOURS[mt][1];

	var row = "<tr>\n<td style='background-color: rowColor;' nowrap>" + [message time] + "<br>";
	row = MESSAGE_TYPES[[message type]] + "</td>\n";
	row = row + "<td style=\"background-color: rowColor;\">";
	if ([message depth] == 0) {
		row = row + [message formattedMessage];
	} else {
		row = row + "<table><tr>";
		for (var i=0; i<[message depth]; i++) {
			row = row + "<td>&nbsp;&nbsp;&nbsp;</td>";
		}
		row = row + "<td>" + [message formattedMessage] + "</td></tr></table>";
	}
	row = row + "</td></tr>\n";
	return row;
}

+ formatAsHtml:(id)dumpMask {
	/* faster to just generate HTML here */

	var messageTable = "";
	messageTable = messageTable + [IFLog htmlOpenTable:dumpMask];
	messageTable = messageTable + [IFLog htmlColumnHeaders:dumpMask];

	for (var i=0; i< [MESSAGE_BUFFER count]; i++) {
        var message = [MESSAGE_BUFFER objectAtIndex:i];
		if (!(dumpMask & [message type])) { continue; }
		messageTable = messageTable + [IFLog htmlRowFromLogEvent:message dumpMask:dumpMask];
	}
	messageTable = messageTable + [IFLog htmlCloseTable:dumpMask];
	return messageTable;
}

+ dumpLogForRequest:(id)request usingLogMask:(id)logMask {
	var messageTable = [IFLog formatAsHtml:logMask];
	[request print:messageTable];
	messageTable = null;
}

+ debug:(id)msg {
    var logMessage = [IFLogMessage newWithType:CODE_DEBUG message:msg depth:_pageStructureDepth];
    [IFLog addMessage:logMessage];
}

+ dump:(id)obj {
	if (!(LOG_MASK & CODE_DEBUG)) { return; }
    if (obj)
        // dump object?
        [IFLog debug:obj];
    }
}

+ page:(id)message {
	[IFLog addMessage:
        [IFLogMessage newWithType:CODE_STRUCTURE message:message depth:_pageStructureDepth]];
}

+ info:(id)message {
	[IFLog addMessage:
        [IFLogMessage newWithType:CODE_INFO message:message depth:_pageStructureDepth]];
}

+ database:(id)message {
	[IFLog addMessage:
        [IFLogMessage newWithType:CODE_DATABASE message:message depth:_pageStructureDepth]];
}

+ error:(id)message {
	[IFLog addMessage:
        [IFLogMessage newWithType:CODE_ERROR message:message depth:_pageStructureDepth]];
    //throw [CPException raise:"CPException" reason:message];
}

+ assert:(id)assertion message:(id)message {
	if (!assertion) {
		var logMessage = [IFLogMessage newWithType:CODE_ASSERTION message:"ASSERTION FAILED: " + message depth:_pageStructureDepth];
		[IFLog addMessage:logMessage];
	}
	return assertion;
}

+ warning:(id)message {
	[IFLog addMessage:
        [IFLogMessage newWithType:CODE_WARNING message:message depth:_pageStructureDepth]];
}

+ code:(id)message {
	[IFLog addMessage:
        [IFLogMessage newtWithType:CODE_CODE message:message depth:_pageStructureDepth]];
}

+ logMaskFromContext {
	return 0xffff;
}

+ logQueryDictionaryFromContext:(id)context {
	if (!(LOG_MASK & CODE_QUERY_DICTIONARY)) { return; }
	var queryDictionary = [context queryDictionary];
    /*
	foreach var key (keys %queryDictionary) {
		var value = queryDictionary[key];
		if (IFArray.isArray(value)) {
			value = join(", ", @value);
		}
		var logMessage = [IFLogMessage new:"key = value" :_pageStructureDepth](CODE_QUERY_DICTIONARY, "key = value", _pageStructureDepth);
		addMessage(logMessage);
	}
    */
}

@end
