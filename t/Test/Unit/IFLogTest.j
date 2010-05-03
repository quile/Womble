@import <IF/Log.j>

@implementation IFLogTest : OJTestCase
{
}

- (void) testLogDebug {
    [IFLog clearMessageBuffer];
    [IFLog debug:"Test debug"];
    [self assert:[[IFLog messageBuffer] count] equals:1];
}

- (void) testLogError {
    [IFLog clearMessageBuffer];
    [IFLog error:"Test error"];
    [self assert:[[IFLog messageBuffer] count] equals:1];
}

- (void) testCheckMask {
    [IFLog clearMessageBuffer];
    [IFLog setLogMask:2];
    [IFLog info:"Test info"];
    [self assert:[[IFLog messageBuffer] count] equals:0];
    [IFLog debug:"Test debug"];
    [self assert:[[IFLog messageBuffer] count] equals:1];
    [IFLog error:"Test error"];
    [self assert:[[IFLog messageBuffer] count] equals:2];
}

- (void) testClearMessageBuffer {
    [IFLog clearMessageBuffer];
    [IFLog debug:"Test debug"];
    [self assert:[[IFLog messageBuffer] count] equals:1];
    [IFLog clearMessageBuffer];
    [self assert:[[IFLog messageBuffer] count] equals:0];
}

@end
