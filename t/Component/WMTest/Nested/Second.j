@import <WM/Component.j>

@implementation WMTestNestedSecond : WMComponent
{
    id password @accessors;
}

+ (CPDictionary) Bindings {
    return {
        password: {
            type: "STRING",
            value: 'password',
        },
    };
}

@end
