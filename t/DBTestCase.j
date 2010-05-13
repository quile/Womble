@import <OJUnit/OJTestCase.j>
@import "Model.j"

@implementation DBTestCase : OJTestCase

- setUp {
    [super setUp];
    [[WMModel defaultModel] dropTables];        
    [[WMModel defaultModel] createTables];        
}

- tearDown {
    [super tearDown];
    [[WMModel defaultModel] dropTables];        
}

@end
