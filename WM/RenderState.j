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

@import "Object.j"

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

- init {
    _pageContext = [1];
	_loopContext = [];
	_renderedComponents = {};
    _pageResources = {};
    _orderedPageResources = [];
	return self;
}

/* These are used in page generation */
- increasePageContextDepth {
    _pageContext[_pageContext.length] = 0;
}

// how do i pop something off the end?
- decreasePageContextDepth {
    if (_pageContext.length <= 1) {
        return;
    }
	return _pageContext.pop();
}

- incrementPageContextNumber {
	_pageContext[ (_pageContext.length-1) ] += 1;
}

// TODO make separator configurable
- pageContextNumber {
	return _pageContext.join("_");
}

/* these mirror the page context stuff but are used
   with a page context for keeping track of loops:
*/
- increaseLoopContextDepth {
    _loopContext[_loopContext.length] = 0;
}

- decreaseLoopContextDepth {
	_loopContext.pop();
}

- incrementLoopContextNumber {
    if (_loopContext.length == 0) {
        _loopContext[0] = 1;
    } else {
        _loopContext[ (_loopContext.length - 1) ] += 1;
    }
}

- loopContextNumber {
    return _loopContext.join("_");
}

- loopContextDepth {
	return _loopContext.length
}

/* ----------- these help components manage page resources --------- */

// FIXME clean up this external API... pageResources = orderedPageResources?
- pageResources {
	return [self _orderedPageResources];
}

/* this holds the resources in the order they are added.  It's not
   particularly accurate because components get included/rendered
   in an order that's not the same as the order they appear on
   the page, BUT it means that all the resources a given component
   requests WILL BE in the order that it requests them.
*/

- _orderedPageResources {
	return _orderedPageResources;
}

- addPageResource:(id)resource {
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
