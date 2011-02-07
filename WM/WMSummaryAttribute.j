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

@import <WM/WMLog.j>
@import <WM/WMDB.j>
@import <WM/WMModel.j>
@import <WM/Entity/WMTransientEntity.j>

@implementation WMSummaryAttribute : WMTransientEntity
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
    var atts = [WMArray new];
    for (var i=4; arguments[i] != nil; i++) {
        [atts addObject:arguments[i]];
    }
    [sa setN:n];
    [sa setSummary:summary];
    [sa setAttributes:atts];
    return sa;
}

- setAttributes:(id)atts {
    attributes = [WMArray arrayFromObject:atts];
}

/* yikes, need to parse this the same way as
   we do with qualifiers... any way to share the code?
*/

- translateSummaryIntoSQLExpression:(id)sqlExpression {
    // FIXME: don't use default model
    var model = [WMModel defaultModel];
    var summaryInSQL = [self summary];
    for (var i=0; i<[attributes count]; i++) {
        var attribute = [attributes objectAtIndex:i];
        [WMLog debug:"Attribute: " + attribute];

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
            [WMLog debug:"Relationship is named " + relationshipName + ", entity is " + [self entity]];
            var relationship = [model relationshipWithName:relationshipName onEntity:[self entity]];

            if (relationship) {
                var targetEntity = [model entityClassDescriptionForEntityNamed:[relationship targetEntity]];
                if (!targetEntity) {
                    [WMLog error:"No target entity found for qualifier self.condition on " + [self entity]];
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
