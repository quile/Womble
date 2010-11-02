@import <WM/WMSummarySpecification.j>
@import <WM/WMSummaryAttribute.j>
@import <WM/WMObjectContext.j>
@import <WM/WMQualifier.j>
@import "Type/DataSource.j"

@implementation TestSummarySpecification : WMDataSourceTest

- (void) testCounting {

    var qualifier = [WMKeyValueQualifier key:"globules.name = %@", "Globule-2"];

    var ss = [WMSummarySpecification new:"WMTestBranch" :qualifier];
    [self assertNotNull:ss message:"Constructed summary spec"];

    [ss restrictFetchToAttributes:"globuleCount"];
    var results = [oc resultsForSummarySpecification:[ss initWithSummaryAttributes:[WMSummaryAttribute new:"globuleCount" :"COUNT(distinct %@)", "id"]]];
    var count = [[results objectAtIndex:0] objectForKey:"globuleCount"];
    [self assert:count equals:2 message:"Found 2 distinct ids for branches with globule-2"];
}

// super crappy test:
- (void) testGroupingSummary {
    var ss = [WMSummarySpecification new:"WMTestGlobule" :[WMKeyValueQualifier key:"branches.length > %@", 0]];
    [ss setGroupBy:"attributeSum"];

    [ss restrictFetchToAttributes:["attributeSum", "globuleCount"]];
    var results = [oc resultsForSummarySpecification:[ss initWithSummaryAttributes:[
            [WMSummaryAttribute new:"attributeSum" :"(LENGTH + LEAF_COUNT)"],
            [WMSummaryAttribute new:"globuleCount" :"COUNT(DISTINCT %@)", "id"],
        ]]];
    [self assert:[results count] equals:1 message:"One result found"];
    [self assert:[[results objectAtIndex:0] objectForKey:"attributeSum"] equals:6 message:"sum is correct"];
    [self assert:[[results objectAtIndex:0] objectForKey:"globuleCount"] equals:6 message:"Found 6 globules whose branches sum to 6"];
}

@end
