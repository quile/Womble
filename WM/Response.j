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
@import "RenderState.j"
//@import "Template.j"

@implementation WMResponse : WMObject
{
    // This is for old-skool compat
    id _params;

    id _contentList;
    WMTemplate _template;
    WMRenderState _renderState;
}

- init {
    _params = {};
    _template = nil;
    _contentList = ['',];
    _renderState = [WMRenderState new],
    [self setContent:""];
    return self;
}

- (void)setTemplate:(WMTemplate)t { _template = t; }
- (WMTemplate) template { return _template; }

/* This shit is for compatibility with crappy old
   templates
*/
- appendContentString:(id)s {
    _contentList[_contentList.length] = s;
}

- (void) setContent:(id)c {
    _contentList = [c];
}

// rename this?  contentAsString?
- (id)content {
    return _contentList.join("");
}

- (WMRenderState)renderState { return _renderState; }
- (void)setRenderState:(WMRenderState)rs { _renderState = rs; }

/* we'll use these to flush content out as it's generated */
- (void)setContentIsBuffered:(Boolean)foo { _contentIsBuffered = foo; }
- (Boolean)contentIsBuffered { return _contentIsBuffered; }

/* how dumb is it that this wasn't on the response? */
- (id) contentType    { return _contentType }
- (void) setContentType:(id)ct { _contentType = ct }

@end
