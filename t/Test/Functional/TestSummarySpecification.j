@import <IF/SummarySpecification.j>
@import <IF/SummaryAttribute.j>
@import <IF/ObjectContext.j>
@import <IF/Qualifier.j>
@import "Type/DataSource.j"

@implementation TestSummarySpecification : IFDataSourceTest

- (void) testCounting {

    var qualifier = [IFKeyValueQualifier key:"globules.name = %@", "Globule-2"];

    var ss = [IFSummarySpecification new:"IFTestBranch" :qualifier];
    [self assertNotNull:ss message:"Constructed summary spec"];
	
    [ss restrictFetchToAttributes:"globuleCount"];
    var results = [oc resultsForSummarySpecification:[ss initWithSummaryAttributes:[IFSummaryAttribute new:"globuleCount" :"COUNT(distinct %@)", "id"]]];
    var count = [[results objectAtIndex:0] objectForKey:"globuleCount"];
    [self assert:count equals:2 message:"Found 2 distinct ids for branches with globule-2"];
}

// super crappy test:
- (void) testGroupingSummary {
    var ss = [IFSummarySpecification new:"IFTestGlobule" :[IFKeyValueQualifier key:"branches.length > %@", 0]];
    [ss setGroupBy:"attributeSum"];
    
    [ss restrictFetchToAttributes:["attributeSum", "globuleCount"]];
    var results = [oc resultsForSummarySpecification:[ss initWithSummaryAttributes:[
            [IFSummaryAttribute new:"attributeSum" :"(LENGTH + LEAF_COUNT)"],
            [IFSummaryAttribute new:"globuleCount" :"COUNT(DISTINCT %@)", "id"],
        ]]];
    [self assert:[results count] equals:1 message:"One result found"];
    [self assert:[[results objectAtIndex:0] objectForKey:"attributeSum"] equals:6 message:"sum is correct"];
    [self assert:[[results objectAtIndex:0] objectForKey:"globuleCount"] equals:6 message:"Found 6 globules whose branches sum to 6"];
}

@end
