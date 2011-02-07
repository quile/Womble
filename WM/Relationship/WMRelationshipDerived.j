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

@import "WMRelationshipModelled.j"

@implementation WMRelationshipDerived : WMRelationshipModelled
{
    WMFetchSpecification fetchSpecification @accessors;
}

+ newFromFetchSpecification:(id)fs withName:(id)n {
    var d = [[self alloc] init];
    d._name = n;
    [d setFetchSpecification:fs];
    return d;
}

- targetEntity {
    return [[self fetchSpecification] entity];
}

- targetEntityClassDescription {
    return [[self fetchSpecification] entityClassDescription];
}

- type {
    return "TO_MANY";
}

/* These aren't defined because there's no actual
   relationship: that has to be applied via a
   separate qualifier
*/

- sourceAttribute {
    return null;
}

- targetAttribute {
    return null;
}

@end
