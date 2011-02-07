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

@import <WM/WMComponent.j>


@implementation WMFormComponent : WMComponent
{
	id name @accessors;
	id isRequired @accessors;
	id validationFailureMessage @accessors;
	id validator @accessors;
	id isRequiredMessage @accessors;
}

- (id) isRequired {
	return isRequired || [self tagAttributeForKey:'isRequired'];
}

// TODO This is bogus because there could be more than one message,
// eg "You must enter an email address" and "You must enter a valid email address"

- (id) validationFailureMessage {
	return validationFailureMessage  || [self tagAttributeForKey:'validationFailureMessage'];
}

- (id) validator {
	return validator || self;
}

- (id) hasValidValues {
	if (isRequired && ![self hasValueForValidation]) {
		return false;
	}
	return true;
}

- (id) isRequiredMessage {
    return isRequiredMessage ||  [self tagAttributeForKey:'isRequiredMessage'];
}

// This might not work for all form components
// but it will simplify
- (id) hasValueForValidation {
	[WMLog warning:"hasValueForValidation has not been implemented " + self];
}

@end
