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

@import <WM/Component.j>


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
