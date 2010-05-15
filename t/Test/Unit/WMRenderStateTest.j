@import <OJUnit/OJTestCase.j>
@import <WM/RenderState.j>

@implementation WMRenderStateTest : OJTestCase

- (void) testPageContext {
    var rs = [WMRenderState new];
    [self assert:[rs pageContextNumber] equals:"1" message:"Initial pc is correct"];
    
    [rs increasePageContextDepth];
    [self assert:[rs pageContextNumber] equals:"1_0" message:"Initial 2nd depth is correct"];

    [rs incrementPageContextNumber];
    [self assert:[rs pageContextNumber] equals:"1_1" message:"Incremeneted 2nd depth is correct"];
}

- (void) testLoopContext {
    var rs = [WMRenderState new];
}

@end
