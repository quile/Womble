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

@import <IF/Log.j>
@import <IF/DB.j>
@import <IF/Model.j>
@import <IF/Entity/Transient.j>

@implementation IFSummaryAttribute : IFTransientEntity
{
    // why doesn't "name" work?
    id n @accessors;
    id summary @accessors;
    id attributes @accessors;
    id qualifiers @accessors;
    id entity @accessors;
}

+ new:(id)n :summary, ... {
    var sa = [super new];
    // pull the args
    var atts = [IFArray new];
    for (var i=4; arguments[i] != nil; i++) {
        [atts addObject:arguments[i]];
    }
    [sa setN:n];
    [sa setSummary:summary];
    [sa setAttributes:atts];
	return sa;
}

- setAttributes:(id)atts {
	attributes = [IFArray arrayFromObject:atts];
}

/* yikes, need to parse this the same way as
   we do with qualifiers... any way to share the code?
*/

- translateSummaryIntoSQLExpression:(id)sqlExpression {
	// FIXME: don't use default model
	var model = [IFModel defaultModel];
	var summaryInSQL = [self summary];
    for (var i=0; i<[attributes count]; i++) {
        var attribute = [attributes objectAtIndex:i];
		[IFLog debug:"Attribute: " + attribute];

		/* check key for compound construct */
		var keyPathElements = [attribute componentsSeparatedByString:/\./];

		var entityClassDescription = [model entityClassDescriptionForEntityNamed:entity];
		var tableAlias;
		var columnName;
		// FIXME use the keypath parsing goo from Qualifier
        // instead of having this hardcoded shite everywhere
		if ([keyPathElements count] > 1) {
			/* traversing a relationship */
			var relationshipName = keyPathElements[0];
			var relationshipKey = keyPathElements[1];
			[IFLog debug:"Relationship is named " + relationshipName + ", entity is " + [self entity]];
			var relationship = [model relationshipWithName:relationshipName onEntity:[self entity]];

			if (relationship) {
				var targetEntity = [model entityClassDescriptionForEntityNamed:[relationship targetEntity]];
				if (!targetEntity) {
					[IFLog error:"No target entity found for qualifier self.condition on " + [self entity]];
					break;
				}
                [sqlExpression addTraversedRelationship:relationshipName onEntity:entityClassDescription];
                var tableName = [targetEntity _table];
                columnName = [targetEntity columnNameForAttributeName:relationshipKey];
                tableAlias = [sqlExpression aliasForTable:tableName];
			} else {
				if (relationshipName =~ /^[DT][0-9]+$/) {
					/* it's a table alias so use it: */
					tableAlias = relationshipName;
					columnName = relationshipKey;
				} else {
					/* maybe it's a table name? */
					tableAlias = [sqlExpression aliasForTable:relationshipName] || relationshipName;
					columnName = [sqlExpression aliasForColumn:relationshipName onTable:relationshipKey] || relationshipKey;
				}
			}
		} else {
			columnName = [entityClassDescription columnNameForAttributeName:attribute];
			var tableName = [entityClassDescription _table];
			tableAlias = [sqlExpression aliasForTable:tableName];
		}

		var columnDefinition = tableAlias + "." + columnName;
        // I can't believe I have to do this.
        var bits = summaryInSQL.split("%@");
        if (bits.length == 2) {
            summaryInSQL = bits.join(columnDefinition);
        } else if (bits.length > 2) {
            // ARGH!
        }
	}
	return summaryInSQL;
}

@end
