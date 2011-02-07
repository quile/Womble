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

@import "WMFetchSpecification.j"

@implementation WMSummarySpecification : WMFetchSpecification
{
    id _groupBy;
    id _summaryAttributes;
    id _summaryQualifier;
}

- init {
    [super init];
    _groupBy = [WMArray new];
    _summaryAttributes = [WMArray new];
    _summaryQualifier = nil;
    return self;
}

- setGroupBy:(id)value {
    _groupBy = [WMArray arrayFromObject:value];
}

- groupBy {
    return _groupBy;
}

- buildSQLExpression {
    /* Call the parent to initialise the sqlExpression object */
    [super buildSQLExpression];

    // FIXME don't use the default model
    var model = [WMModel defaultModel];

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
        [WMLog debug:"[ Summary Qualifier: " + [sqlQualifier sql] + " Bind values: " + [sqlQualifier bindValues] + " ]"];
        [[self sqlExpression] setSummaryQualifier:[sqlQualifier sql]];
        var newBindValues = [WMArray arrayFromObject:[sqlQualifier bindValues]];
        if ([newBindValues count] > 0) {
            var bindValues = [[self sqlExpression] bindValues];
            [bindValues addObjectsFromArray:newBindValues];
            [[self sqlExpression] setQualifierBindValues:bindValues];
        }
    }
}

- setSummaryAttributes:(id)value {
    _summaryAttributes = [WMArray arrayFromObject:value];
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
    var objectContext = [WMObjectContext new];
    var dictionaries = [WMArray new];
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
    return [WMSQLStatement newWithSQL:"SELECT COUNT(*) AS COUNT FROM (" + [[self sqlExpression] selectStatement] + ") AS CT" andBindValues:[[self sqlExpression] bindValues]];
}

@end
