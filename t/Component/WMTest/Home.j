@import <WM/Component.j>

@implementation WMTestHome : WMComponent
{
    id allowsDirectAccess @accessors;
}

- (id) zibzab { return "Zabzib!" }
- (id) foo {
    return [WMDictionary dictionaryWithJSObject:{
        bar: "Fascination!",
        baz: {
            banana: "mango",
        },
    }];
}

- (id) idol {
    return [WMDictionary dictionaryWithJSObject:{
            tosser: "Simon Cowell",
            nice: "Paula Abdul",
            funny: "Ryan Seacrest",
            cool: "Randy Jackson",
        }];
}

- (id) goop {
    return "YAK!";
}

+ (CPDictionary) Bindings {
    return {
        header: {
            type: "STRING",
            value: '"Jabberwock"',
        },
        //system_test: {
        //    type: "URL",
        //    bindings: {
        //        url: '"http://b3ta.com"',
        //    },
        //},
    };
}

@end
