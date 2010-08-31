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

@import <WM/ObjectContext.j>
@import <WM/Qualifier.j>
@import <WM/Entity/Transient.j>
@import <WM/Component.j>
@import <WM/Helpers.js>

var FILE = require("file");

var DEFAULT_SITE_CLASSIFIER;
var SYSTEM_COMPONENT_NAMESPACE = "WM";
var BINDINGS_ROOT;
var SYSTEM_BINDINGS_ROOT;
var SYSTEM_TEMPLATE_ROOT;
var SITE_CLASSIFIER_MAP = {};
var BINDING_CACHE       = {};
var TEMPLATE_MAP        = {};
var COMPONENT_MAP       = {};
var COMPONENT_LOAD_ATTEMPTS = {};

var SITE_CLASSIFIERS_BY_NAME = {};
var SITE_CLASSIFIERS_BY_COMPONENT_CLASS_NAME = {};
var SITE_CLASSIFIERS_BY_ID = {};

@implementation WMSiteClassifier : WMTransientEntity
{
    id id @accessors;
    id parentId @accessors;
    id name @accessors;
    id languages @accessors;
    id defaultLanguage @accessors;
    id city @accessors;
    id state @accessors;
    id country @accessors;
    id _languages;
    id _languageMap;
    id _defaultBindings @accessors(property=defaultBindings);
    id _defaultLanguage @accessors(property=defaultLanguage);
    id _componentClassName @accessors(property=componentClassName);
}


+ SITE_CLASSIFIERS {
    return [
        { id: 1, name: "root", languages: ["en"], defaultLanguage: "en", },
    ];
}

+ (id) componentClassName {
    return "WM";
}

+ (WMSiteClassifier) siteClassifierWithName:(id)n {
    if (SITE_CLASSIFIERS_BY_NAME[n]) { return SITE_CLASSIFIERS_BY_NAME[n] }
    var ss = [self SITE_CLASSIFIERS].filter(function (s) { return (s['name'] == n) });
    if (!ss.length) {
        return nil;
    }
    return SITE_CLASSIFIERS_BY_NAME[n] = [self newFromDictionary:[CPDictionary dictionaryWithJSObject:ss[0]]];
}

+ (WMSiteClassifier) siteClassifierWithComponentClassName:(id)n {
    if (SITE_CLASSIFIERS_BY_COMPONENT_CLASS_NAME[n]) { return SITE_CLASSIFIERS_BY_COMPONENT_CLASS_NAME[n] }
    var ss = [self SITE_CLASSIFIERS].filter(function (s) { return (s.name == n) });
    if (!ss.length) {
        return nil;
    }
    return SITE_CLASSIFIERS_BY_COMPONENT_CLASS_NAME[n] = [self newFromDictionary:[CPDictionary dictionaryWithJSObject:ss[0]]];
}

+ (WMSiteClassifier) instanceWithId:(id)i {
    if (SITE_CLASSIFIERS_BY_ID[i]) { return SITE_CLASSIFIERS_BY_ID[i] }
    var ss = [self SITE_CLASSIFIERS].filter(function (s) { return (s.id == i) });
    if (!ss.length) {
        return nil;
    }
    return SITE_CLASSIFIERS_BY_ID[i] = [self newFromDictionary:[CPDictionary dictionaryWithJSObject:ss[0]]];
}

+ (WMArray) all {
    var all = [];
    var scs = [self SITE_CLASSIFIERS];
    var i = scs.length;
    while (i--) {
        var e = scs[i];
        all.push([self siteClassifierWithName:[e name]]);
    }
    return all;
}

// this should be enough - I don't think children() is ever called.
- (WMSiteClassifier) parent {
    if (![self parentId]) { return nil }
    var c = [self class];
    return [c instanceWithId:[self parentId]];
}

// bogus since we don't have an address abstraction
/*
- location {
    return undef if $self->name() eq "root";
    return IF::Dictionary->new({
        city: $self->city(),
        state: $self->state(),
        country: $self->country(),
    });
}
*/

/*
sub locationAsString {
    my ($self) = @_;
    my $ls = [];
    push (@$ls, $self->city()) if $self->city();
    push (@$ls, $self->state()) if $self->state();
    push (@$ls, $self->country()) if $self->country();
    return join(", ", @$ls);
}
*/

+ (WMSiteClassifier) defaultSiteClassifierForApplication:(id)application {
	if (!DEFAULT_SITE_CLASSIFIER) {
		var defaultSiteClassifierName = [application configurationValueForKey:"DEFAULT_SITE_CLASSIFIER_NAME"];
		if ([WMLog assert:defaultSiteClassifierName message:"Default site classifier is defined in app config"]) {
			DEFAULT_SITE_CLASSIFIER = [self siteClassifierWithName:defaultSiteClassifierName];
		}

		// if we still don't have one, return undef.  This will be caught by the context
		// which will bail.
        if (!DEFAULT_SITE_CLASSIFIER) { return nil }
	}
	return DEFAULT_SITE_CLASSIFIER;
}

- (Boolean) hasParent {
	return ([self parentId] != 0);
}

- (CPString) defaultBindFileName {
	return "Default";
}

- path {
	return [self componentClassName];
}

- componentPath {
	return [self componentClassName];
}

- languages {
	return _languages.split(":");
}

- setLanguages:(id)values {
    values = [WMArray arrayFromObject:values];
	_languages = values.join(":");
}

- (Boolean) hasLanguage:(id)language {
	if (!_languageMap) {
		_languageMap = {};
        var ls = [self languages];
        var i = ls.length;
		while (i--) {
            l = ls[i];
			_languageMap[l] = true;
		}
	}
	return Boolean(_languageMap[language]);
}

- listOfAncestors {
    if (![self hasParent]) { return [] }
    var ancestors = [CPArray new];
    [ancestors addObject:parent];
    [ancestors addObjectsFromArray:[[self parent] listOfAncestors]];
    return ancestors;
}

- resolutionOrder {
    var ro = [CPArray new];
    [ro addObject:self];
    [ro addObjectsFromArray:[self listOfAncestors]];
    return ro;
}

// site classifiers now become responsible for the resolution of the template/binding/class for a
// given name

// FIXME:kd THis stuff is not relevant really any more moving to obj-j
- (id) relativeNameForComponentName:(id)componentName {
	if ([self pathIsSystemPath:componentName]) { return componentName }
	var componentClassName = [self componentClassName];
    // This means that the site classifier hasn't specified a component class name;
    // if this is so, we can't generate a relative name so just return the component name.
    if (!componentClassName) {
        return componentName;
    }
    var cre = new RegExp("^" + componentClassName + "(.+)$");
    var match;
	if (match = componentName.match(cre)) {
		return match[1];
	}
	if ([self hasParent]) {
		return [[self parent] relativeNameForComponentName:componentName];
	}
	return componentName;
}

- (id) bestTemplateForPath:(id)path andContext:(id)context {
	var languageToken;
	var application;
	var preferredLanguages;

	if (context) {
	    application = [context application];
	    languageToken = [context preferredLanguagesForTransactionAsToken];
	    preferredLanguages = [context preferredLanguagesForTransaction];
	} else {
	    application = [WMApplication defaultApplication];
	    languageToken = [application configurationValueForKey:"DEFAULT_LANGUAGE"];
	    preferredLanguages = [languageToken];
	}

	var templateLookupKey = [languageToken, [self name], path].join("/");
    SYSTEM_TEMPLATE_ROOT = SYSTEM_TEMPLATE_ROOT || [WMApplication systemConfigurationValueForKey:"SYSTEM_TEMPLATE_ROOT"];
	var cachedTemplatePath = TEMPLATE_MAP[templateLookupKey];
    if (cachedTemplatePath) {
		//WM::Log::debug("Short-circuiting template search, returning cached template at $cachedTemplatePath");
		var t = [WMTemplate cachedTemplateForPath:cachedTemplatePath];
        if (t) return t;
		[WMLog debug:"Didn't find cached template in the template cache, so just loading it directly"];
		// SW: This should be rare, I've pushed the config lookup down here to avoid calling it in
		// the heavy traffic bit of this method above
		var shouldCacheTemplates = [WMApplication systemConfigurationValueForKey:"SHOULD_CACHE_TEMPLATES"];
        t = [WMTemplate newWithName:filename andPaths:nil shouldCache:shouldCacheTemplates];
		if (t) return t;
		[WMLog debug:"Couldn't load it directly, so falling back to regular search paths"];
	}

	var checkedLanguages = {};
	var template;
	var templateRoot = [application configurationValueForKey:"TEMPLATE_ROOT"];
	var shouldCacheTemplates = [WMApplication systemConfigurationValueForKey:"SHOULD_CACHE_TEMPLATES"];

	// resolution path for templates is different than components or bindings
	// because we resolve by language first.  Therefore, we check for a template in
	// language X until we have exhausted all possibilities, then go to the
	// next language

    var pll = preferredLanguages.length;
    for (var i=0; i<pll; i++) {
        var language = preferredLanguages[i];
		var sc = self;
		if (checkedLanguages[language]) { continue }
		checkedLanguages[language] += 1;

		while (1) {
			var scPath = [sc path] || [application name];

			var scRoot = [templateRoot, scPath, language].join("/");
    	    [WMLog debug:"Looking for template " + path +" in " + scRoot];

            template = [WMTemplate newWithName:path andPaths:[scRoot]
                                   shouldCache:shouldCacheTemplates];

            if (template) { break }
			if ([sc hasParent]) {
				sc = [sc parent];
			} else {
				break;
			}
		}

        if (template) { break }
		[WMLog debug:"Didn't find template for language " + language];
	}

	// If we still haven't found it, try the system templates:
	if (!template) {
		//WM::Log::debug("Trying to load $path from $SYSTEM_TEMPLATE_ROOT");
        var paths = [ SYSTEM_TEMPLATE_ROOT + "/WM", templateRoot + "/WM" ];
		template = [WMTemplate newWithName:filename andPaths:paths cache:shouldCacheTemplates];
		if (template) {
			[WMLog debug:"Found system template"];
		}
	}

	if (!template) {
 		[WMLog error:"no template file found for " + path];
	} else {
        [WMLog info:"Found template at " + [template fullPath]];
		if ([WMApplication systemConfigurationValueForKey:"SHOULD_CACHE_TEMPLATE_PATHS"]) {
			TEMPLATE_MAP[templateLookupKey] = [template fullPath];
		}
	}

	return template;
}

// This inheritance context stuff is bogus; plus, the whole variable # of args
// in Perl thing is killing me... I'm glad we didn't use it much.
//- (id) bindingsForPath:(id)path inContext:(id)context {
//    return [self bindingsForPath:path inContext:context :nil];
//}
//
//- (id) bindingsForPath:(id)path inContext:(id)context :(id)inheritanceContext {
//	inheritanceContext = inheritanceContext || [WMDictionary new];
//
//	// we need to strip off the site classifier prefix from the path
//	// if it was included
//	var scPrefix = [self path];
//	// ISSUE: 2326....Could not have a SiteClassifier with the same name as a Component
//	// since it was requiring 0 or more /....this makes the / required.
//    var pre = new RegExp("^" + scPrefix + "/");
//    path = path.replace(pre, "");
//
//    var hashKey = ["/", scPrefix, path].join("/");
//
//	// for bindings, we search until we find one, and then follow the inheritsFrom
//	// tree
//
//	if (BINDING_CACHE[hashKey]) {
//		[WMLog debug:"Returning cached bindings for " + hashKey];
//		return BINDING_CACHE[hashKey];
//	}
//
//	var application = context ? [context application] : [WMApplication defaultApplication];
//
//    var siteClassifierPath = [self path] || [application name];
//
//	// now we start checking from this site classifier and continue up the
//	// site classifier tree until we find one
//	var bindingsRoot = [application configurationValueForKey:"BINDINGS_ROOT"];
//
//	SYSTEM_BINDINGS_ROOT = SYSTEM_BINDINGS_ROOT || [WMApplication systemConfigurationValueForKey:"FRAMEWORK_ROOT"] + "/lib";
//
//	[WMLog debug:bindingsRoot + ":" + siteClassifierPath + ":" + path];
//
//	var bindFile = bindingsRoot + '/' + siteClassifierPath + '/' + path + '.bind'; // TODO:kd make the suffix configurable
//	var bindings = [self _bindingGroupForFullPath:bindFile inContext:context :inheritanceContext];
//
//	if (bindings.length == 0) {
//		if ([self hasParent]) {
//			bindings = [[self parent] bindingsForPath:path inContext:context :inheritanceContext];
//		}
//	}
//
//	if (bindings.length == 0) {
//		// Check the system bindings since we haven't located anything yet
//		//my $systemBindFile = $bindingsRoot.'/WM/'.$path.'.bind';
//		var systemBindFile = SYSTEM_BINDINGS_ROOT + "/WM/Component/" + path + ".bind";
//		//WM::Log::debug("Loading system bind file $systemBindFile if possible");
//		var systemBindingGroup = [self _bindingGroupForFullPath:systemBindFile inContext:context :inheritanceContext];
//		if (systemBindingGroup.length) {
//			bindings = systemBindingGroup;
//			[WMLog debug:"Successfully loaded system binding group " + systemBindFile];
//		}
//	}
//
//	var bindingsHash = {};
//	//WM::Log::dump($bindings);
//	if (bindings.length == 0) {
//		[WMLog warning:"Couldn't load bindings for " + path];
//		return {};
//	}
//    // update them in reverse order to make sure the
//    // highest priority ones win
//
//    for (var i = bindings.length; i>0; i--) {
//        var binding = bindings[i-1];
//        bindingsHash = bindingsHash.update(binding);
//    }
//
//	// add them to the bindings cache and return them
//	if ([WMApplication systemConfigurationValueForKey:"SHOULD_CACHE_BINDINGS"]) {
//		//WM::Log::debug(" ==> stashing bindings for $path in cache <== ");
//		//WM::Log::dump($bindings);
//		BINDING_CACHE[hashKey] = bindingsHash;
//	}
//	return bindingsHash;
//}
//
//- (id) _bindingGroupForFullPath:(id)fullPath inContext:(id)context :(id)inheritanceContext {
//    inheritanceContext = inheritanceContext || [WMDictionary new];
//
//	// This should stop it from exploding.
//	if (inheritanceContext[fullPath]) {
//	    [WMLog warning:"Averting possible infinite recursion in binding resolution of " + fullPath];
//	    return [];
//	}
//
//	var bindings = [];
//	var b;
//
//	var application = context ? [context application] : [WMApplication defaultApplication];
//
//	BINDINGS_ROOT = BINDINGS_ROOT || [application configurationValueForKey:"BINDINGS_ROOT"];
//	SYSTEM_BINDINGS_ROOT = SYSTEM_BINDINGS_ROOT || [WMApplication systemConfigurationValueForKey:"FRAMEWORK_ROOT"] + "/lib";
//
//	var c = fullPath;
//    c = c.replace(/\.bind$/, "");
//    var bre = new RegExp("^" + BINDINGS_ROOT + "/");
//    c = c.replace(bre, "");
//    var sre = new RegExp("^" + SYSTEM_BINDINGS_ROOT + "/");
//    c = c.replace(sre, "");
//
//    cn = [self _bestComponentNameForName:c inContext:context];
//	[WMLog debug:"Component name is " + c];
//    if (cn) {
//        var cncls = objj_getClass(cn);
//        try {
//            if (cncls && [cncls respondsToSelector:@SEL("Bindings")]) {
//                var bd = [cncls Bindings];
//                if (bd) {
//                    [WMLog debug:"Found Bindings() method in " + cn];
//                    b = [[WMBindingDictionary new] initWithDictionary:bd];
//                }
//            }
//        } catch (e) {
//            [WMLog error:e];
//        }
//    }
//
//	if (!b) {
//    	try {
//            var fp = FILE.path(fullPath).canonical();
//            var bf = require(fp);
//            if (bf) {
//                b = [[CPDictionary alloc] initWithDictionary:bf.BINDINGS];
//            } else {
//                [WMLog warning:"Failed to load bindings at path " + fullPath];
//            }
//    		inheritanceContext[fullPath]++;
//    	} catch (e) {
//    		[WMLog error:e];
//    	}
//    }
//	if (b) {
//		bindings.push(b);
//
//		//WM::Log::debug("^^^^^^^^^^^^ Checking for inheritance");
//		if (b['inheritsFrom']) {
//			var ancestor = b['inheritsFrom'];
//			[WMLog debug:"^^^^^^^^^^^^^^ inherits from " + ancestor];
//			if ([self pathIsSystemPath:ancestor]) {
//				//ancestor =~ s/SYSTEM_COMPONENT_NAMESPACE\:\://;
//			}
//			//ancestor =~ s/::/\//g;
//
//			// TODO bulletproof this... it would be possible and EASY to send this
//			// into an infinite spin by having a loop in inheritance (binding A depends on
//			// other bindings files that somehow depend on A)
//
//            bindings.push([self bindingsForPath:ancestor inContext:context :inheritanceContext]);
//		} else {
//
//			// If there's no specific parent, we're at the root of the user-specified
//			// inheritance tree, so we will suck in the default binding if it exists
//			// making sure we don't get stuck in a resolution loop for the default binding
//			// file too...
//			var defaultBinding = [application configurationValueForKey:"DEFAULT_BINDING_FILE"];
//			if (defaultBinding) {
//                var dbre = new RegExp("/" + defaultBinding + ".bind");
//                if (!fullPath.match(dbre)) {
//                    [WMLog debug:"Sucking in default bindings " + defaultBinding];
//				    bindings.push([self bindingsForPath:defaultBinding inContext:context :inheritanceContext]);
//                }
//			}
//		}
//	}
//	return bindings;
//}

- (WMComponent) componentForBinding:(id)binding inContext:(id)context {
    // Allow the user to specify components as either
	// type => COMPONENT value => bindingClass
	//      or
	// type => bindingClass
	var bindingClass = binding.value || binding.type;
	// Locate the component and the template
	var componentName = [WMUtility evaluateExpression:bindingClass inComponent:self context:context] || bindingClass;

	//WM::Log::debug(" ******** ". $binding->{_NAME} .": $bindingClass, $self, $componentName *********");
    if (![WMLog assert:componentName message:"Component path exists for binding " + binding._NAME]) { return nil }

	// we need full classname of component here.
	var fullComponentClassName = [self _bestComponentNameForName:componentName inContext:context];
	if (fullComponentClassName) {
        var cls = objj_getClass(fullComponentClassName);
	    return [cls newWithBinding:binding];
	}
	return nil;
}

- (WMComponent) componentForName:(id)componentName andContext:(id)context {
	var component;
	[WMLog debug:" ++++!!!!++++ componentName"];

	var hashKey = [self name] + "/" + componentName;

	// if we have found this before, we can return an
	// instance of the mapped class
	if (COMPONENT_MAP[hashKey]) {
		var componentPath = COMPONENT_MAP[hashKey];
		try {
		    component = [componentPath new];
		} catch (e) {
            // do nothing
        }
		if (component) {
			[WMLog debug:"Returning component from cached path " + componentPath + " for " + componentName];
			return component;
		}
	}

	component = [self bestComponentForName:componentName inContext:context];

	if (component) {
		var componentPath = [component class];
		[WMLog debug:"Bingo, found " + componentName + " at " + componentPath];
		COMPONENT_MAP[hashKey] = componentPath;
	}

	return component;
}

// This is not as efficient as generating them ad-hoc, but
// it's much easier to debug and to extend.
- (CPArray) possibleComponentNamesForName:(id)componentName inNamespaces:(id)namespaces {

    var names = [];
    for (var i=0; i<namespaces.length; i++) {
        ns = namespaces[i];
		if (![self pathIsSystemPath:ns] && [self componentPath]) {
			ns = ns + [self componentPath];
		}
        // <namespace><componentName>
        names.push(ns + componentName);
        // <namespace><componentName with namespace stripped off the front>
        var nsre = new RegExp("^" + ns);
        var strippedComponentName = componentName.replace(nsre, "");
        names.push(ns + strippedComponentName);
    }
    return names;
}

- (CPString) _bestComponentNameForName:(id)componentName inContext:(id)context {
	var application = context ? [context application] : [WMApplication defaultApplication];
	var componentNamespaces = [application configurationValueForKey:"COMPONENT_SEARCH_PATH"];
	var bestComponentPath;

    // Generate a list of names to try
    var possibleNames = [self possibleComponentNamesForName:componentName inNamespaces:componentNamespaces];

    for (var i = 0; i<possibleNames.length; i++) {
        var componentPath = possibleNames[i];
        [WMLog info:"Trying " + componentPath + " as component class"];
        var cls = objj_getClass(componentPath);
        if (cls && [cls respondsToSelector:@SEL("new")]) {
			bestComponentPath = componentPath;
		} else {
			[WMLog debug:"Couldn't instantiate " + componentPath];
			if ([self hasParent]) {
				[WMLog debug:"Didn't find it in site classifier " + [self name] + " so checking parent"];
				bestComponentPath = [[self parent] _bestComponentNameForName:componentName inContext:context];
			}
		}
		if (bestComponentPath) { break }
	}
	// return nil by design if no workable path is found
	return bestComponentPath;
}

- (WMComponent) bestComponentForName:(id)componentName inContext:(id)context {
	var resolvedComponentName = [self _bestComponentNameForName:componentName inContext:context];
	if (resolvedComponentName) {
        var cls = objj_getClass(resolvedComponentName);
		return [cls new];
	} else {
		return nil;
	}
}

- (id) preferredLanguagesForTemplateResolutionInContext:(id)context {
	return [];
}

// The default implementation of this just delegates the
// URL generation to the WMUtility method.  However,
// a site classifier should be able to override generation
// of its URLs, which it can do by overriding this method.
// This is uber-handy for things like Facebook apps.
+ urlInContext:(id)context forDirectAction:(id)directActionName
                               onComponent:(id)componentName
                       withQueryDictionary:(id)qd {

	return [WMUtility urlInContext:context
                   forDirectAction:directActionName
                       onComponent:componentName
               withQueryDictionary:qd];
}

// yikes
- (Boolean) pathIsSystemPath:(id)path {
    if (!path) { return false }
    if (path.match(/^WMComponent/)) { return true }
    return false;
}

@end
