@import <OJUnit/OJTestCase.j>
@import <WM/RenderState.j>
@import <WM/Helpers.js>

@implementation WMRenderStateTest : OJTestCase

- (void) testPageContext {
    var rs = [WMRenderState new];
    [self assert:[rs pageContextNumber] equals:"1" message:"Initial pc is correct"];
    
    [rs increasePageContextDepth];
    [self assert:[rs pageContextNumber] equals:"1_0" message:"Initial 2nd depth is correct"];

    [rs incrementPageContextNumber];
    [self assert:[rs pageContextNumber] equals:"1_1" message:"Incremented 2nd depth is correct"];

    [rs incrementPageContextNumber];
    [rs increasePageContextDepth];
    [self assert:[rs pageContextNumber] equals:"1_2_0" message:"Yada yada yada"];

    [rs decreasePageContextDepth];
    [self assert:[rs pageContextNumber] equals:"1_2" message:"Decreasing depth"];
}

- (void) testLoopContext {
    var rs = [WMRenderState new];

    [self assert:[rs loopContextNumber] equals:"" message:"Empty"];

    [rs incrementLoopContextNumber];
    [self assert:[rs loopContextNumber] equals:"1" message:"One"];

    [rs increaseLoopContextDepth];
    [self assert:[rs loopContextNumber] equals:"1_0" message:"Increased depth"];

    [rs increaseLoopContextDepth];
    [rs incrementLoopContextNumber];
    [rs incrementLoopContextNumber];
    [self assert:[rs loopContextNumber] equals:"1_0_2" message:"Increased depth and number"];

    [rs decreaseLoopContextDepth];
    [self assert:[rs loopContextNumber] equals:"1_0" message:"Decreasing depth"];
}

- (void) testDecreaseDepth {
    var rs = [WMRenderState new];

    [self assert:[rs pageContextNumber] equals:"1" message:"Initial state is ok"];
    [rs decreasePageContextDepth];
    [self assert:[rs pageContextNumber] equals:"1" message:"Decreasing from initial state does nothing"];

    [rs decreaseLoopContextDepth];
    [self assert:[rs pageContextNumber] equals:"1" message:"Decreasing loop context does nothing"];
}

@end
