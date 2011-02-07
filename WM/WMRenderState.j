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

@import "WMObject.j"

// TODO: implement this as a category
// IFInterfaceStatusMessageHandling
// IFPageResourceHandling
@implementation WMRenderState : WMObject
{
    id _pageContext;
    id _loopContext;
    id _renderedComponent;
    id _pageResources;
    id _orderPageResources;
}

- (WMRenderState) init {
    _pageContext = [1];
	_loopContext = [];
	_renderedComponents = {};
    _pageResources = {};
    _orderedPageResources = [];
	[WMLog debug:"Initialising render state..."];
	return self;
}

/* These are used in page generation */
- (void) increasePageContextDepth {
    _pageContext[_pageContext.length] = 0;
}

// how do i pop something off the end?
- (id) decreasePageContextDepth {
    if (_pageContext.length <= 1) {
        return;
    }
	return _pageContext.pop();
}

- (void) incrementPageContextNumber {
	_pageContext[ (_pageContext.length-1) ] += 1;
}

// TODO make separator configurable
- (id) pageContextNumber {
	return _pageContext.join("_");
}

/* these mirror the page context stuff but are used
   with a page context for keeping track of loops:
*/
- (void) increaseLoopContextDepth {
    _loopContext[_loopContext.length] = 0;
}

- (id) decreaseLoopContextDepth {
	_loopContext.pop();
}

- (void) incrementLoopContextNumber {
    if (_loopContext.length == 0) {
        _loopContext[0] = 1;
    } else {
        _loopContext[ (_loopContext.length - 1) ] += 1;
    }
}

- (id) loopContextNumber {
    return _loopContext.join("_");
}

- (id) loopContextDepth {
	return _loopContext.length
}

/* ----------- these help components manage page resources --------- */

// FIXME clean up this external API... pageResources = orderedPageResources?
- (CPArray) pageResources {
	return [self _orderedPageResources];
}

/* this holds the resources in the order they are added.  It's not
   particularly accurate because components get included/rendered
   in an order that's not the same as the order they appear on
   the page, BUT it means that all the resources a given component
   requests WILL BE in the order that it requests them.
*/

- (CPArray) _orderedPageResources {
	return _orderedPageResources;
}

- (void) addPageResource:(id)resource {
	/* Only add it to the list if it's not already there. */
	var location = [resource location];
	if (!_pageResources[location]) {
		[WMLog debug:"Requesting resource " + location];
		_orderedPageResources[_orderedPageResources.length] = resource;
	}
	_pageResources[location] = resource;
}

- addPageResources:(id)resources {
	resources = [WMArray arrayFromObject:resources];
	for (var i=0; i < [resources count]; i++) {
        var r = resources[i];
		[self addPageResource:r];
	}
}

- removePageResource:(id)resource {
	delete _pageResources[[resource location]];
}

@end
