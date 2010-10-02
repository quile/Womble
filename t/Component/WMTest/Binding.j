@import <WM/Component.j>
@import <WM/PageResource.j>

@implementation WMTestBinding : WMComponent
{
    id allowsDirectAccess @accessors;
}

- (id) hovercraft {
    return "full of eels";
}

- (id) record {
    return "scratched";
}

- (id) Bindings {
    return {
        keypath_binding: {
            type: "STRING",
            value: keypath('hovercraft'),
        },
        kp_binding: {
            type: "STRING",
            value: kp('record'),
        },
        raw_binding: {
            type: "STRING",
            value: raw("tobacconist"),
        },
        objj_binding: {
            type: "STRING",
            value: objj("[[self hovercraft] uppercaseString]"),
        },
        js_binding: {
            type: "STRING",
            value: js("(function() { return 'eels' }).apply()"),
        },
    };
}

@end
