@import <OJUnit/OJTestCase.j>
@import <WM/WMPageResource.j>


@implementation WMPageResourceTest : OJTestCase

- (void) testInitialise {
    var pr = [WMPageResource javascript:"/foo/bar.js"];
    [self assert:[pr location] equals:"/foo/bar.js"];
    [self assert:[pr mimeType] equals:"text/javascript"];
    [self assert:[pr type] equals:"javascript"];

    var pr = [WMPageResource stylesheet:"/banana/mango.css"];
    [self assert:[pr location] equals:"/banana/mango.css"];
    [self assert:[pr mimeType] equals:"text/css"];
}

- (void) testBasicTags {
    var pr = [WMPageResource javascript:"/foo/bar.js"];
    [self assert:[pr tag] equals:'<script type="text/javascript" src="/foo/bar.js?v=1.0"></script>'];

    var pr = [WMPageResource stylesheet:"/fawlty/towers.css"];
    [self assert:[pr tag] equals:'<link rel="stylesheet" type="text/css" href="/fawlty/towers.css?v=1.0" media="screen, print" title="" />'];
}

@end
