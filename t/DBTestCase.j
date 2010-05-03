@import <OJUnit/OJTestCase.j>
@import "Model.j"

@implementation DBTestCase : OJTestCase

- setUp {
    [super setUp];
    [[IFModel defaultModel] dropTables];        
    [[IFModel defaultModel] createTables];        
}

- tearDown {
    [super tearDown];
    [[IFModel defaultModel] dropTables];        
}

@end
