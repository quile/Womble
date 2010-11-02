@import <WM/WMLog.j>

@implementation WMLogTest : OJTestCase
{
}

- (void) testLogDebug {
    [WMLog clearMessageBuffer];
    [WMLog debug:"Test debug"];
    [self assert:[[WMLog messageBuffer] count] equals:1];
}

- (void) testLogError {
    [WMLog clearMessageBuffer];
    [WMLog error:"Test error"];
    [self assert:[[WMLog messageBuffer] count] equals:1];
}

- (void) testCheckMask {
    [WMLog clearMessageBuffer];
    [WMLog setLogMask:2];
    [WMLog info:"Test info"];
    [self assert:[[WMLog messageBuffer] count] equals:0];
    [WMLog debug:"Test debug"];
    [self assert:[[WMLog messageBuffer] count] equals:1];
    [WMLog error:"Test error"];
    [self assert:[[WMLog messageBuffer] count] equals:2];
}

- (void) testClearMessageBuffer {
    [WMLog clearMessageBuffer];
    [WMLog debug:"Test debug"];
    [self assert:[[WMLog messageBuffer] count] equals:1];
    [WMLog clearMessageBuffer];
    [self assert:[[WMLog messageBuffer] count] equals:0];
}

@end
