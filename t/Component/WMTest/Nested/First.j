@import <WM/Component.j>

@import "Second.j"

@implementation WMTestNestedFirst : WMComponent
{
    id password @accessors;
}

+ (CPDictionary) Bindings {
    return {
        second: {
            type: "WMTestNestedSecond",
            bindings: {
                password: 'password',
            },
        },
    };
}

@end
