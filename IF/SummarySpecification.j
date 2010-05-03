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

@import "FetchSpecification.j"

@implementation IFSummarySpecification : IFFetchSpecification
{
    id _groupBy;
    id _summaryAttributes;
    id _summaryQualifier;
}

- init {
    [super init];
    _groupBy = [IFArray new];
    _summaryAttributes = [IFArray new];
    _summaryQualifier = nil;
    return self;
}

- setGroupBy:(id)value {
	_groupBy = [IFArray arrayFromObject:value];
}

- groupBy {
	return _groupBy;
}

- buildSQLExpression {
	/* Call the parent to initialise the sqlExpression object */
	[super buildSQLExpression];

    // FIXME don't use the default model
	var model = [IFModel defaultModel];

	/* call SQLExpression to add the groupBy stuff */
	if ([[self groupBy] count] > 0) {
		[[self sqlExpression] setGroupBy:[self groupBy]];
	}

	/* add the summary attributes to the sqlExpression */
	if ([_summaryAttributes count] > 0) {
		var ecd = [model entityClassDescriptionForEntityNamed:entity];
        var table = [ecd _table];
        for (var i=0; i < [_summaryAttributes count]; i++) {
            var summaryAttribute = [_summaryAttributes objectAtIndex:i];
			[[self sqlExpression] addSummaryAttribute:summaryAttribute forTable:table];
		}
	}

	/* if there is a summary qualifier, evaluate those and add them */
	if ([self hasSummaryQualifier]) {
		var sqlQualifier = [[self summaryQualifier] sqlWithBindValuesForExpression:[self sqlExpression] andModel:model andClause:"HAVING"];
		[IFLog debug:"[ Summary Qualifier: " + [sqlQualifier sql] + " Bind values: " + [sqlQualifier bindValues] + " ]"];
		[[self sqlExpression] setSummaryQualifier:[sqlQualifier sql]];
		var newBindValues = [IFArray arrayFromObject:[sqlQualifier bindValues]];
		if ([newBindValues count] > 0) {
			var bindValues = [[self sqlExpression] bindValues];
            [bindValues addObjectsFromArray:newBindValues];
			[[self sqlExpression] setQualifierBindValues:bindValues];
		}
	}
}

- setSummaryAttributes:(id)value {
	_summaryAttributes = [IFArray arrayFromObject:value];
    for (var i=0; i<[_summaryAttributes count]; i++) {
        var summaryAttribute = [_summaryAttributes objectAtIndex:i];
		[summaryAttribute setEntity:entity];
	}
}

- initWithSummaryAttributes:(id)summaryAttributes {
	[self setSummaryAttributes:summaryAttributes];
	return self;
}

- setSummaryQualifier:(id)value {
	_summaryQualifier = value;
	[_summaryQualifier setEntity:entity];
}

- hasSummaryQualifier {
	return (_summaryQualifier != nil);
}

- unpackResultsIntoDictionaries:(id)results {
	var primaryKey = [[entityClassDescription _primaryKey] asString].toUpperCase();
	var objectContext = [IFObjectContext new];
	var dictionaries = [IFArray new];
    for (var i=0; i < [results count]; i++) {
        var result = [results objectAtIndex:i];
		[dictionaries addObject:[[self sqlExpression] dictionaryFromRawRow:result]];
	}
	return dictionaries;
}

- toCountSQLFromExpression {
	var fl = [self fetchLimit];
	[self setFetchLimit:nil];
	[self buildSQLExpression];
	[self setFetchLimit:fl];

	/* Generate the SQL for the whole statement, and return it and
	   the bind values ready to be passed to the DB
    */
	return [IFSQLStatement newWithSQL:"SELECT COUNT(*) AS COUNT FROM (" + [[self sqlExpression] selectStatement] + ") AS CT" andBindValues:[[self sqlExpression] bindValues]];
}

@end
