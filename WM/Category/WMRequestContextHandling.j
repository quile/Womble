@import <WM/WMObject.j>

@implementation WMRequestContextHandling : WMObject

// Placing this code here is a bit of a stop-gap
// solution while I'm porting the session-handling
// over to use various backends.  It will probably
// not live here very long, but you'll never need
// it so who cares?

- (void) addRenderedComponent:(id)component {
	var pageContextNumber = [component renderContextNumber];
	var componentName = [component componentName];
	_renderedComponents[componentName][pageContextNumber] = _renderedComponents[componentName][pageContextNumber] || 0;
	_renderedComponents[componentName][pageContextNumber]++;
	_renderedPageContextNumbers[pageContextNumber] = _renderedPageContextNumbers[pageContextNumber] || 0;
	_renderedPageContextNumbers[pageContextNumber]++;
}

+ (Boolean) didRenderComponentWithPageContextNumber:(id)pcn {
	[WMLog debug:"Checking if we rendered component with context number " + pcn];
    if (_renderedPageContextNumbers[pcn] > 0) {
        [WMLog debug:"..........----> Yep."];
        return true;
    }
	var re = new RegExp(pcn + 'L[0-9_]+$');

	for (var k in _renderedPageContextNumbers) {
		if (k.match(re)) {
            [WMLog debug:"..........----> Yep."];
		    return true;
		}
	}
    [WMLog debug:"..........----> Nope."];
	return false;
}

- (Boolean) didRenderComponentWithName:(id)componentName {
	//IF::Log::debug("Checking if we rendered component with name $componentName");
    [WMLog debug:"Checking if we rendered component with name " + componentName];
	var n = _renderedComponents[componentName];
	if (n) {
        [WMLog debug:"..........----> Yep."];
	    return true;
	}
    [WMLog debug:"..........----> Yep."];
	[self dumpRenderedComponents];
	return false;
}

- (id) pageContextNumbersForComponentWithName:(id)componentName {
	return _renderedComponents[componentName];
}

- (id) pageContextNumberForCallingComponent:(id)componentName inContext:(id)context {
	if (![self didRenderComponentWithName:componentName]) { return nil };
	for (var pageContextNumber in _renderedComponents[componentName]) {
		for (var i=0; i < [[context formKeys] count]; i++) {
            var key  = [context formKeys][i];
            if (!key.match(/^[0-9_]+$/)) { continue }
            if (key.match(new RegExp(_p_quotemeta(pageContextNumber)))) {
                return pageContextNumber;
            }
		}
	}
	return nil;
}

- (id) dumpRenderedComponents {
    [WMLog dump:_renderedComponents];
}

@end