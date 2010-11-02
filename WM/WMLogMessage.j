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

/*=======================================
   Represents a single message in the
   Log message buffer
  =======================================
*/
@import <Foundation/CPDate.j>
@import "WMObject.j"
@import "WMLog.j"

@implementation WMLogMessage : WMObject
{
    CPString type @accessors;
    CPString message @accessors;
    Number depth @accessors;
    CPString caller @accessors;
    CPDate time @accessors;
}

+ newWithType:(id)aType andMessage:(id)message {
    return [[super alloc] initWithType:aType andMessage:message];
}

+ newWithType:(id)aType message:(id)aMessage depth:(id)aDepth {
    return [[super alloc] initWithType:aType message:aMessage depth:aDepth];
}

- initWithType:(id)aType andMessage:(id)aMessage {
    [self setType:aType];
    [self setTime:[CPDate date]];
    [self setMessage:aMessage];
    return self;
}

- initWithType:(id)aType message:(id)aMessage depth:(id)aDepth {
    [self initWithType:aType andMessage:aMessage];
    [self setDepth:depth];
    return self;
}

- (CPString) content {
    return [self stringWithEvaluatedKeyPaths:[self message] inLanguage:"en"]
}

- (CPString) description {
    return [CPString stringWithFormat:"[%s] <%s> - %s", [self time],
                [WMLog messageTypeStringForType:[self type]], [self message]];
}

- (CPString) formattedMessage {
    return message;
/* TODO
    var width = shift || 50;
    var message = [self content];
    var formattedMessage = "";
    while (length(message) > width) {
        formattedMessage .= substr(message, 0, width);
        if (substr(message, 0, width) !~ /\w/) {
            formattedMessage .= " ";
        }
        message = substr(message, width);
    }
    formattedMessage = formattedMessage + message;
    return formattedMessage;
    */
}

- (CPString) formattedTime {
    return [[self time] description];
}

@end
