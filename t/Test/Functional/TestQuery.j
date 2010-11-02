@import <WM/WMQuery.j>
@import <WM/WMLog.j>
@import <WM/WMObjectContext.j>
@import <OJUnit/OJTestCase.j>
@import "../../Classes.j"
@import "../../Application.j"
@import "Type/DataSource.j"

var application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation TestQuery : WMDataSourceTest
{
}

- (void) setUp {
    [super setUp];
    //[WMLog setLogMask:0xffff];
}

- (void) tearDown {
    //[WMLog setLogMask:0x0000];
    [super tearDown];
}

- (void) testBasic {
    var basic = [WMQuery new:"WMTestRoot"];
    var all = [basic all];
    [self assert:[all count] equals:1 message:"Basic query [all] returned correct number"];

    var basic = [WMQuery new:"WMTestBranch"];
    var all = [basic all];
    [self assert:[all count] equals:6 message:"Basic query [all] returned correct number when more than 1 result"];
}

- (void) testIterate {
    // Simple fetch of 1 item
    var query = [WMQuery new:"WMTestTrunk"];
    [self assertNotNull:[query next] message:"Fetched object correctly"];
    [self assertNull:[query next] message:"Iteration terminated correctly"];

    // Simple fetch of more than 1 item
    var query = [WMQuery new:"WMTestBranch"];
    [self assertTrue:(  [query next]
                     && [query next]
                     && [query next]
                     && [query next]
                     && [query next]
                     && [query next]) message:"Fetch six objects using [next]"];
    [self assertNull:[query next] message:"Iteration terminated correctly"];
}

- (void) testFilter {
    // Simple filter with one term
    var query = [[WMQuery new:"WMTestRoot"] filter:"title = %@", "Foosball"];
    [self assertNull:[query next] message:"No result found when one-term filter doesn't match"];
    var query = [[WMQuery new:"WMTestRoot"] filter:"title LIKE %@", "Roo%"];
    [self assertTrue:([query next] && ![query next]) message:"Exactly one result found when one-term filter matches"];
    // find exact match
    var query = [[WMQuery new:"WMTestRoot"] filter:"title = %@", "Root"];
    [self assertNotNull:[query next] message:"Result found when one-term filter with bind value matches"];
    var query = [[WMQuery new:"WMTestRoot"] filter:"title = 'Root'"];
    [self assertNotNull:[query next] message:"Result found when one-term filter with no bind value matches"];

    // try filter with no bind values
    var query = [[WMQuery new:"WMTestBranch"] filter:"length > 4"];
    [self assertTrue:([query next] && ![query next]) message:"Found one result using filter without bind values"];

    // try more than one filter
    var query = [[[WMQuery new:"WMTestBranch"] filter:"length < %@", 2] filter:"leafCount > %@", 4];

    [self assertTrue:([query next] && [query next] && ![query next]) message:"Found two results with 2 filters"];

    // adjust the filter and check
    var query = [[[WMQuery new:"WMTestBranch"] filter:"length < %@", 2] filter:"leafCount > %@", 5];
    [self assertTrue:([query next] && ![query next]) message:"Found one result using two filters"];
}

- (void) testCount {
    var query = [[WMQuery new:"WMTestBranch"] filter:"leafCount > 4"];
    [self assert:[query count] equals:2 message:"Counted correct number of branches"];

    var query = [WMQuery new:"WMTestBranch"];
    [self assert:[query count] equals:6 message:"Counted correct number of branches with no filter"];
}

- (void) testReset {
    var query = [[WMQuery new:"WMTestBranch"] filter:"length > 4"];
    var nid = [[query next] id];
    [query reset];
    [self assert:[[query next] id] equals:nid message:"Reset query started it over again"];
}

- (void) testJoin {
    // TODO test the objects when they come back and make sure
    // they're the right objects.
    var query = [[WMQuery new:"WMTestRoot"] filter:"trunk.thickness > 10"];
    [self assertTrue:([query next] && ![query next]) message:"Found one object when qualifying via a join"];

    var query = [[WMQuery new:"WMTestRoot"] filter:"trunk.branches.leafCount > 5"];
    [self assertTrue:([query next] && ![query next]) message:"Found one object via two joins"];

}

- (void) testLimit {
    var query = [[WMQuery new:"WMTestBranch"] filter:"leafCount > 2"];
    [self assert:[query count] equals:4 message:"Counted 4 branches"];

    [[query reset] limit:2];
    [self assertTrue:([query next] && [query next] && ![query next]) message:"Limited fetch that matches 4 to 2 results"];
}

- (void) testOrdering {
    var query = [[WMQuery new:"WMTestBranch"] orderBy:"leafCount"];
    [self assert:[[query first] leafCount] equals:1 message:"First item has correct count"];
    [[query reset] orderBy:"leafCount DESC"];
    [self assert:[[query first] leafCount] equals:6 message:"First item has correct count"];
}

- (void) testPrefetching {
    [oc clearTrackedEntities];
    var query = [WMQuery new:"WMTestTrunk"];
    var trunk = [query first];
    [self assertTrue:(trunk && [[trunk _cachedEntitiesForRelationshipNamed:"branches"] count] == 0) message:"No items prefetched"];
    [[query reset] prefetch:"branches"];
    var trunk = [query first];
    [self assertTrue:(trunk && [[trunk _cachedEntitiesForRelationshipNamed:"branches"] count] == 6) message:"Prefetched all branches"];
}

@end;
