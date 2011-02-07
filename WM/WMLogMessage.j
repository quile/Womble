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
