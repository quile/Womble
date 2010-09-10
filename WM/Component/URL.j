/* --------------------------------------------------------------------
 * WM - Web Framework and ORM heavily influenced by WebObjects & EOF
 * (C) kd 2010
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

var QS = require("querystring");

@import <Foundation/CPArray.j>
@import <Foundation/CPDictionary.j>
@import <WM/Component.j>
@import <WM/Utility.j>
@import <WM/Web/ActionLocator.j>

@implementation WMComponentURL : WMComponent
{
	id protocol @accessors;
	id action @accessors;
	id directAction @accessors;
	id siteClassifierName @accessors;
	id targetComponentName @accessors;
	id url @accessors;
	id sessionId @accessors;
	id queryDictionary @accessors;
	id rawQueryDictionary @accessors;
	id queryString @accessors;
	id anchor @accessors;
	id urlRoot @accessors;
	id language @accessors;
	id shouldEnsureDefaultProtocol @accessors;
	id shouldSuppressQueryDictionary @accessors;
	id queryDictionaryAdditions @accessors;
	id queryDictionarySubtractions @accessors;
	id queryDictionaryReplacements @accessors;
}

- (id) init {
	//my $application = $self->context()->application();
	//$self->setDirectAction($application->configurationValueForKey("DEFAULT_DIRECT_ACTION"));

	action = nil;
	directAction = nil;
	siteClassifierName = nil;
	targetComponentName = nil;
	url = nil;
	sessionId = nil;
	queryDictionary = {};
	rawQueryDictionary = {};
	queryString = nil;
	shouldSuppressQueryDictionary = false;
	queryDictionaryAdditions = [];
	queryDictionarySubtractions = [CPDictionary new];
	queryDictionaryReplacements = [CPDictionary new];
	return self;
}

- (id) action {
	if (action) { return action }

	var componentName = targetComponentName;
	if (componentName == "") {
		componentName = [[self rootComponent] componentNameRelativeToSiteClassifier];
		if ([self parent]) {
			var pageContextNumber = [[self parent] pageContextNumber];
			if (pageContextNumber != "1") {
			    directAction = pageContextNumber + "-" + directAction;
		    }
		}
	}

	//componentName =~ s!::!/!g;
	//var root     = [self urlRoot];
	//var language = [self language];

	var al = [WMWebActionLocator new];
	[al setUrlRoot:root];
	[al setSiteClassifierName:siteClassifierName];
	[al setLanguage:language];
	[al setTargetComponentName:componentName];
	[al setDirectAction:directAction];

	var application = [self context] ? [[self context] application] : [WMApplication defaultApplication];
	var module = [application moduleInContext:[self context] forComponentNamed:componentName];
	//if (module) {
	//	var ou = [module urlFromActionLocatorAndQueryDictionary:al, self->queryDictionaryAsHash()](al, self->queryDictionaryAsHash());
	//	// testing:
	//	//my $iu = $module->urlFromIncomingUrl($ou);
	//	//IF::Log::debug("That maps back to $iu");
	//
	//	[self setShouldSuppressQueryDictionary:1](1) unless ou == al->asAction();
	//	return ou;
	//} else {
		return [al asAction];
	//}
}

- (id) protocol {
	return protocol || "http";
}

- (id) siteClassifierName {
	return siteClassifierName || [[self _siteClassifier] name];
//	return $self->context()->siteClassifier()->name() ||
//		$self->context()->application()->configurationValueForKey("DEFAULT_SITE_CLASSIFIER_NAME");
}

- (id) language {
	if (language) { return language }
	if ([self context]) { return [[self context] language] }
	return [[self application] configurationValueForKey:"DEFAULT_LANGUAGE"];
}

- (id) urlRoot {
	return urlRoot || [[self application] configurationValueForKey:"URL_ROOT"];
}

- (id) hasQueryDictionary {
	var qd = [self queryDictionary];
	if (qd && typeof qd == "object" && qd.keys().length > 0) return true;
	if ([queryDictionaryAdditions count]) return true;
	if ([[queryDictionaryReplacements allKeys] count]) return true;
	if (queryString.length) return true;
	var rqd = [self rawQueryDictionary];
	if (rqd && typeof rqd == "object" && rqd.keys().length > 0) return true;
	return false;
}

- (void) setQueryDictionary:(id)qd {
	// dopey kyle: make a copy before changing this, seeing as
	// how it's BOUND IN from outside!
	var qdCopy = [[WMDictionary new] initWithDictionary:qd];
	queryDictionary = qdCopy;
	// expand the values and evaluate in the context of the parent:
	var keys = [qdCopy allKeys];
	for (var i=0; i < keys.length; i++) {
		var key = keys[i];
		var value = [WMUtility evaluateExpression:[qdCopy objectForKey:key] inComponent:[self parent] context:[self context]];
		[qdCopy setObject:value forKey:key];
	}
}

- (id) queryDictionaryKeyValuePairs {
	var keyValuePairs = [WMArray new];
	var usedKeys = [WMDictionary new];

	// first we do the additions:
	var additions = [self queryDictionaryAdditions];
	var subtractions = [self queryDictionarySubtractions];
	var replacements = [self queryDictionaryReplacements];

	for (var i=0; i < [additions count]; i++) {
		var addition = [additions objectAtIndex:i];
		var key = addition['NAME'];
		if ([self shouldSuppressQueryDictionaryKey:key]) { continue }
		var value = [replacements objectForKey:key] || addition['VALUE'];
		[keyValuePairs addObject:{ NAME: key, VALUE: value}];
		[usedKeys setObject:true forKey:key];
	}

	// if there's a query string, unpack it and use it instead of the query dictionary
	var qd = [self queryDictionary];
	if ([self queryString]) {
		[WMLog debug:"Unpacking from query string " + [self queryString]];
		qd = [WMDictionary dictionaryFromQueryString:[self queryString]];
	}
	var rqd = [self rawQueryDictionary];

	// next we go through the query dictionary itself
	// and skip values that are "subtracted".  We also
	// replace values that are "replaced"
	var ds = [qd, rqd];
	for (var i=0; i < ds.length; i++) {
		var d = ds[i];
		var keys = _p_keys(d);
		for (var ki=0; ki < keys.length; ki++) {
			var key = keys[ki];
			if ([self shouldSurpressQueryDictionaryKey:key]) { continue }
			var value = [replacements objectForKey:key] || d[key];

			// handle the multiple values:
			var values = [WMArray arrayFromObject:value];

			for (var vi=0; vi < values.length; vi++) {
				var v = values[vi];
				[keyValuePairs addObject:{ NAME: key, VALUE: v }];
			}
			[usedKeys setObject:true forKey:key];
		}
	}


	// Lastly, we make sure there are no unused values in the "replacements"
	var rpks = _p_keys(replacements);
	for (var ki = 0; ki < rpks.length; ki++) {
		var key = rpks[ki];
		if ([usedKeys hasObjectForKey:key]) { continue }
		var values = [WMArray arrayFromObject:[replacements objectForKey:key]];
			for (var vi=0; vi < values.length; vi++) {
				var v = values[vi];
				[keyValuePairs addObject:{ NAME: key, VALUE: v }];
			}
		}
	}
	[WMLog dump:keyValuePairs];
	return keyValuePairs;
	//return [sort {$a->{NAME} cmp $b->{NAME}} @$keyValuePairs];
}

- (id) queryDictionaryAsQueryString {
	var qd = [self queryDictionaryKeyValuePairs];
	var qstr = [];
	for (var i=0; i < [qd count]; i++) {
		var kvp = [qd objectAtIndex:i];
		var k = kvp['NAME'];
		var v = [self escapeQueryStringValue:kvp['VALUE']];
		qstr.push(k + "=" + v);
	}
	return qstr.join("&");
}

- (id) queryDictionaryAsHash {
	var qd = [self queryDictionaryKeyValuePairs];
	var qdh = {};
	for (var i=0; i<[qd count]; i++) {
		var kvp = [qd objectAtIndex:i];
		qdh[kvp['NAME']] = kvp['VALUE'];
	}
	return qdh;
}

- (id) targetComponentName {
	return targetComponentName || [self tagAttributeForKey:"page"];
}

- (id) directAction {
	if (directAction) { return directAction }
	var ta = [self tagAttributeForKey:"action"];
	if (ta) { return ta }
	var application = [self context] ? [[self context] application] : [WMApplication defaultApplication];
	return [application configurationValueForKey:"DEFAULT_DIRECT_ACTION"];
}

- (id) shouldSuppressQueryDictionaryKey:(id)key {
	return [queryDictionarySubtractions hasObjectForKey:key];
}

// a binding starting with "^" will direct this component
// to REPLACE the query dictionary entry with that key with the specified value.
// a binding starting with "+" will direct this component
// to ADD the key/value pair to the query dictionary
// a binding starting with "-" will direct this component
// to REMOVE that key/value pair from the query dictionary (the value is ignored)

- (id) setValue:(id)value forKey:(id)key {
	var match = key.match(/^(\^|\+|\-)(.*)$/);
	if (match) {
		return [super setValue:value forKey:key];
	}
	var action = match[1];
	key = match[2];
	if (action == "+") {
		var values = [WMArray arrayFromObject:value];
		for (var i=0; i < [values count]; i++) {
			var v = [values objectAtIndex:i];
			[queryDictionaryAdditions addObject:{ NAME: key, VALUE: v }];
		}
	} else if (action == "-") {
		[queryDictionarySubtractions setObject:"1" forKey:key];
	} else if (action == "^") {
		[queryDictionaryReplacements setObject:value forKey:key];
	}
	return;
}

- (id) escapeQueryString:(id)string {
	return QS.escape(string);
	//if (Encode::is_utf8(string)) {
	//	return URI::Escape::uri_escape_utf8(string);
	//} else {
	//	return URI::Escape::uri_escape(string);
	//}
}

- (id) hasCompiledResponse {
	if ([self componentNameRelativeToSiteClassifier] == "WMComponentURL") { return true }
	return false;
}

// This has been unrolled to speed it up; do not be tempted to do this
// anywhere else!

- (id) asString {
	var html = "";

	var u = [self url];
	if (u) {
		if ([self shouldEnsureDefaultProtocol]) {
			// If we don't have the :// of the protocol and it's not relative meaning begins with /...
			if (!u.match(/(:\/\/|^\/)/)) {
				var application = [self context] ? [[self context] application] : [WMApplication defaultApplication];
				var prot = [application configurationValueForKey:"DEFAULT_PROTOCOL"] || "http://";
				// Prepend the default protocol
				u = prot + u;
			}
		}
		html = html + u;
	} else {
		if (server) {
			var prot = [self protocol];
			if (prot) {
				html = html + prot + "://";
			} else {
				html = html + "http://";
			}

			html = html + [self server];
		}

		html = html + [self action];

		if ([self hasQueryDictionary]) {
			var qs = "";
			var isFirst = true;
			if (![self shouldSuppressQueryDictionary]) {
				var kvps = [self queryDictionaryKeyValuePairs];
				for (var i=0; i < [kvps count]; i++) {
					var kvPair = [kvps objectAtIndex:i];
					if (!isFirst) {
						qs = qs + "&";
					}
					isFirst = false;

					qs = qs + [self escapeQueryString:kvPair['NAME']];
					qs = qs + "=";
					qs = qs + [self escapeQueryString:kvPair['VALUE']];
				}
				if (qs) {
					html = html + "?" + qs;
				}
			}
		}
		if ([self anchor]) {
			html = html + '#' + [self anchor];
		}
	}
	return html;
}

- (id) appendToResponse:(id)response inContext:(id)context {
	if ([self hasCompiledResponse] && [self componentNameRelativeToSiteClassifier] == "URL") {
		[response setContent:[self asString]];
	} else {
		[super appendToResponse:response inContext:context];
	}
	[self init]; // Clear this instance so it can be re-used next time
	return;
}

- (id) externalSessionId {
	if (!sessionId) { return "0:0" }
	return [WMUtility externalIdForId:sessionId];
}

@end
