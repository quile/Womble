@import <IF/ObjectContext.j>
@import "Type/DataSource.j"

@implementation TestObjectContext : IFDataSourceTest

- (void) testTrackNewObject {
    var e = [IFTestGlobule new];
    [self assertFalse:[e isTrackedByObjectContext] message:"New object is not being tracked"];
    [self assertFalse:[oc entityIsTracked:e] message:"Object context knows nothing of new object"];
}

@end
