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

@import <Foundation/CPKeyValueCoding.j>
@import "Persistent.j"

@implementation IFModelledEntity : IFPersistentEntity {

// TODO: how do I dynamically alter the inheritance
// tree?  Easy in perl, not sure about objj!

/* Dealing with the Chicken-Egg problem */
/*
+ import:(id)c {
    var modelClass = c;
    modelClass =~ /( + *)::( + *)$/;
    modelClass = 1 + "::Model::_" + 2;
    no strict 'refs';
	var i = \@{c + "::ISA"};
	if (i && scalar @i > 0 && i.0 == modelClass) {
	    IFLog.debug("Not pushing model class onto ISA because it's already there");
	    return;
	}
	// add model class to the mix
    eval "use modelClass;";

    unless ($@) {
        unshift @i, modelClass;
    } else {
        eval "use IFEntityPersistent;";
        unshift @i, "IFEntityPersistent";
    }
}
*/

@end
