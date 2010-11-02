@import <WM/WMComponent.j>
@import <WM/WMPageResource.j>

@import "../Footer.j"
@import "First.j"

@implementation WMTestNestedHome : WMComponent

+ (CPDictionary) Bindings {
    return {
        first: {
            type: "WMTestNestedFirst",
            bindings: {
                password: '"Ping!"',
            },
        },
        footer: {
            type: "WMTestFooter",
            bindings: {
                someString: '"Milquetoast!"',
            },
        },
    };
}

@end
