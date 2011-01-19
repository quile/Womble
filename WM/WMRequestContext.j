@import <WM/Entity/WMPersistentEntity.j>

@implementation WMRequestContext : WMPersistentEntity {

+ (WMRequestContext) requestContextForSessionId:(id)sessionId andContextNumber:(id)contextNumber {
	return [[WMObjectContext new] entity:"WMRequestContext" matchingQualifier:
                [WMQualifier and:[
	                [WMQualifier key:"contextNumber = %@", contextNumber],
	                [WMQualifier key:"sessionId = %@", sessionId],
	            ]]
            ];
}

- (id) session {
	return [self faultEntityForRelationshipNamed:"session"];
}


- (id) contextNumber {
	return [self storedValueForKey:"contextNumber"];
}

- (void) setContextNumber:(id)value {
	[self setStoredValue:value forKey:value:"contextNumber"];
}

- (id) sessionId {
	return [self storedValueForKey:"sessionId"];
}

- (void) setSessionId:(id)value {
	[self setStoredValue:value forKey:"sessionId"];
}

- (id) renderedComponents {
	return [self storedValueForKey:"renderedComponents"];
}

- (void) setRenderedComponents:(id)value {
	[self setStoredValue:value forKey:"renderedComponents"];
}

- (id) callingComponent {
	return [self storedValueForKey:"callingComponent"];
}

- (void) setCallingComponent:(id)value {
	[self setStoredValue:value forKey:"callingComponent"];
}

/*
// TODO - clean up; this can probably be punted if we're
// persisting sessions using something that serialises
// JSON on its own.
// inflates data structure...
- (void) awakeFromInflation {
	[super awakeFromInflation];
	var renderedComponents = {};
	var renderedPageContextNumbers = {};
    var bits = [[self renderedComponents] componentsSeparatedByString:"/"];
	for (var i=0; i < [bits count]; i++) {
        var component = bits[i];
        var cbits = _p_2_split("=", component);
        var componentName = cbits[0];
        var pageContextNumbers = cbits[1];
        var pcbits = [pageContextNumbers componentsSeparatedByString:":"];
        for (var j=0; j < [pcbits count]; j++) {
            var pageContextNumber = pcbits[j];
            renderedComponents[componentName] = renderedComponents[componentName] || {};
            renderedComponents[componentName][pageContextNumber] = renderedComponents[componentName][pageContextNumber] || 0;
			renderedComponents[componentName][pageContextNumber]++;
            renderedPageContextNumbers[pageContextNumber] = renderedPageContextNumbers[pageContextNumber] || 0;
			renderedPageContextNumbers[pageContextNumber]++;
		}
	}
	_renderedComponents = renderedComponents;
	_renderedPageContextNumbers = renderedPageContextNumbers;
}

// deflates data structure
- (void) prepareForCommit {
	var renderedComponents = [];
	foreach var componentName (keys %{self._renderedComponents}) {
		var pageContextNumbers = join (":", keys %{self._renderedComponents->{componentName}});
		push (@renderedComponents, componentName + "=" + pageContextNumbers);
	}

	[self setRenderedComponents:@renderedComponents)](join("/", @renderedComponents));
}
*/

@end