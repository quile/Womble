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
@import "WMRenderState.j"

@implementation WMResponse : WMObject
{
    id _contentList @accessors(property=contentList);
    WMRenderState _renderState;
    id _status @accessors(property=status);
    id _headers @accessors(property=headers);
}

- init {
    _contentList = ['',];
    _renderState = nil;
    _status = 200;
    // sensible default, I think... you can reset it easily yourself.
    _headers = {
        "Content-type": "text/html; charset=utf-8"
    };
    [self setContent:""];
    return self;
}

- (void) appendContentString:(id)s {
    _contentList[_contentList.length] = s;
}

- (void) setContent:(id)c {
    _contentList = [c];
}

- (id) content {
    return _contentList.join("");
}

- (id) body {
    return [self content];
}

- (WMRenderState) renderState {
    if (!_renderState) {
        _renderState = [WMRenderState new];
    }
    return _renderState;
}

- (void) setRenderState:(WMRenderState)rs { _renderState = rs; }

- (id) contentType    { return _headers['Content-type'] }
- (void) setContentType:(id)ct { _headers['Content-type'] = ct }

@end
