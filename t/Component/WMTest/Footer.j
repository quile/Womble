@import <WM/Component.j>
@import <WM/PageResource.j>

@implementation WMTestFooter : WMComponent
{
    // This gets pushed in from the enclosing component via bindings
    id someString @accessors;
}

// testing page resources
- (id) requiredPageResources {
    return [
        [WMPageResource stylesheet:"/brillig/slithy.css"],
    ]
}

- (id) someKey {
    return "Bing!";
}


- (id) Bindings {
    return {
        some_key: {
            type: "STRING",
            value: 'someKey',
        },
        some_string: {
            type: "STRING",
            value: 'someString',
        },
    };
}

@end
