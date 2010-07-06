@import <WM/ObjectContext.j>
@import <WM/Qualifier.j>
//@import <WM/BindingDictionary.j>
/*
	WMEntityPersistent
	WMInterfaceStash
*/

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

@implementation WMSiteClassifier : WMObject
{
    id _languages;
    id _defaultBindings @accessors(property=defaultBindings);
    id _defaultLanguage @accessors(property=defaultLanguage);
    id _componentClassName @accessors(property=componentClassName);
}

// This is not really relevant any more now that this shite has
// been moved into "fixtures" rather than the DB.
/*
+ siteClassifierWithName:(id)name {
	var sc = SITE_CLASSIFIER_MAP.name->{name};
	unless (sc) {
		// try to pull the object from memcache if we don't have it
		// (won't have cached bindings etc... but saves a hit on the db)
		sc = [className stashedValueForKey:'name-' + name]('name-' + name);
		unless (sc) {
			var objectContext = [WMObjectContext new];
			sc = [objectContext entitiesMatchingQualifier:name)]("SiteClassifier", 
									[WMQualifier key:"name = %@" :name]("name = %@", name))->[0];
			unless (sc) {
				WMLog.error("Failed to fetch a site classifier for name");
				return null;
			}
			[className setStashedValueForKey:sc,'name-' + name](sc,'name-' + name);
			[className setStashedValueForKey:sc,'scname-' + sc->componentClassName()](sc,'scname-' + sc->componentClassName());
		}
		SITE_CLASSIFIER_MAP.name->{name} = sc;
		SITE_CLASSIFIER_MAP.componentClassName->{[sc componentClassName]} = sc;
	}
	return sc;
}

+ siteClassifierWithComponentClassName:(id)componentClassName {
	var sc = SITE_CLASSIFIER_MAP.componentClassName->{componentClassName};
	unless (sc) {
		sc = [className stashedValueForKey:'scname-' + componentClassName]('scname-' + componentClassName);
		unless (sc) {
			var objectContext = [WMObjectContext new];
			sc = [objectContext entitiesMatchingQualifier:componentClassName)]("SiteClassifier", 
									[WMQualifier key:"componentClassName = %@" :componentClassName]("componentClassName = %@", componentClassName))->[0];
			unless (sc) {
				WMLog.error("Failed to fetch a site classifier for compnent class name componentClassName");
				return null;
			}
			[className setStashedValueForKey:sc,'name-' + sc->name()](sc,'name-' + sc->name());
			[className setStashedValueForKey:sc,'scname-' + componentClassName](sc,'scname-' + componentClassName);
		}
		SITE_CLASSIFIER_MAP.componentClassName->{componentClassName} = sc;
		SITE_CLASSIFIER_MAP.name->{[sc name]} = sc;		
	}
	return sc;
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
	if (pathIsSystemPath(componentName)) { return componentName }
	var componentClassName = [self componentClassName];
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
			var scPath = [sc path];

			var scRoot = [templateRoot, scPath, language.toUpperCase()].join("/");
    	    [WMLog debug:"Looking for template " + path +" in " + scRoot];

            template = [WMTemplate newWithName:filename andPaths:[scRoot]
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
		if ([WMApplication systemConfigurationValueForKey:"SHOULD_CACHE_TEMPLATE_PATHS"]) {
			TEMPLATE_MAP[templateLookupKey] = [template fullPath];
		}
	}

	return template;
}

// This inheritance context stuff is bogus; plus, the whole variable # of args
// in Perl thing is killing me... I'm glad we didn't use it much.
- (id) bindingsForPath:(id)path inContext:(id)context {
    return [self bindingsForPath:path inContext:context :nil];
}

- (id) bindingsForPath:(id)path inContext:(id)context :(id)inheritanceContext {
	inheritanceContext = inheritanceContext || [WMDictionary new];
	
	// we need to strip off the site classifier prefix from the path
	// if it was included
	var scPrefix = [self path];
	// ISSUE: 2326....Could not have a SiteClassifier with the same name as a Component
	// since it was requiring 0 or more /....this makes the / required.
    var pre = new RegExp("^" + scPrefix + "/");
    path = path.replace(pre, "");

    var hashKey = ["/", scPrefix, path].join("/");
	
	// for bindings, we search until we find one, and then follow the inheritsFrom
	// tree
	
	if (BINDING_CACHE[hashKey]) {
		[WMLog debug:"Returning cached bindings for " + hashKey];
		return BINDING_CACHE[hashKey];
	}

	var application = context ? [context application] : [WMApplication defaultApplication];

	// now we start checking from this site classifier and continue up the 
	// site classifier tree until we find one
	var bindingsRoot = [application configurationValueForKey:"BINDINGS_ROOT"];

	SYSTEM_BINDINGS_ROOT = SYSTEM_BINDINGS_ROOT || [WMApplication systemConfigurationValueForKey:"FRAMEWORK_ROOT"] + "/lib";
	
	[WMLog debug:bindingsRoot + ":" + [self path] + ":" + path];

	var bindFile = bindingsRoot + '/' + [self path] + '/' + path + '.bind'; // TODO:kd make the suffix configurable
	var bindings = [self _bindingGroupForFullPath:bindFile inContext:context :inheritanceContext];
	
	if (bindings.length == 0) {
		if ([self hasParent]) {
			bindings = [[self parent] bindingsForPath:path inContext:context :inheritanceContext];
		}
	}
	
	if (bindings.length == 0) {
		// Check the system bindings since we haven't located anything yet
		//my $systemBindFile = $bindingsRoot.'/WM/'.$path.'.bind';
		var systemBindFile = SYSTEM_BINDINGS_ROOT + "/WM/Component/" + path + ".bind";
		//WM::Log::debug("Loading system bind file $systemBindFile if possible");
		var systemBindingGroup = [self _bindingGroupForFullPath:systemBindFile inContext:context :inheritanceContext];
		if (systemBindingGroup.length) {
			bindings = systemBindingGroup;
			[WMLog debug:"Successfully loaded system binding group " + systemBindFile];
		}
	}
	
	var bindingsHash = {};
	//WM::Log::dump($bindings);
	if (bindings.length == 0) {
		[WMLog warning:"Couldn't load bindings for " + path];
		return {};
	}
    // update them in reverse order to make sure the
    // highest priority ones win
    
    for (var i = bindings.length; i>0; i--) {
        var binding = bindings[i-1];
        bindingsHash = bindingsHash.update(binding);
    }
	
	// add them to the bindings cache and return them
	if ([WMApplication systemConfigurationValueForKey:"SHOULD_CACHE_BINDINGS"]) {
		//WM::Log::debug(" ==> stashing bindings for $path in cache <== ");
		//WM::Log::dump($bindings);
		BINDING_CACHE[hashKey] = bindingsHash;
	}
	return bindingsHash;
}

+ _bindingGroupForFullPathInContext:(id)inheritanceContext {
    inheritanceContext = inheritanceContext || [WMDictionary new];
	
	// This should stop it from exploding.
	if (inheritanceContext[fullPath]) {
	    [WMLog warning:"Averting possible infinite recursion in binding resolution of " + fullPath];
	    return [];
	}

	var bindings = [];
	var b;
		
	var application = context ? [context application] : [WMApplication defaultApplication];
	
	// HACK!  This is to allow a component to store its bindings within the .pm
	// file:
	BINDINGS_ROOT = BINDINGS_ROOT || [application configurationValueForKey:"BINDINGS_ROOT"];
	SYSTEM_BINDINGS_ROOT = SYSTEM_BINDINGS_ROOT || [WMApplication systemConfigurationValueForKey:"FRAMEWORK_ROOT"] + "/lib";
	
	var p = [self path];
	var c = fullPath; 
    c = c.replace(/\.bind$/, "");
    var bre = new RegExp("^" + BINDINGS_ROOT + "/");
    c = c.replace(bre, "");
    var sre = new RegExp("^" + SYSTEM_BINDINGS_ROOT + "/");
    c = c.replace(sre, "");
	// c =~ s/^p\///g;
	// c =~ s/\//::/g;
	// $c should be the component name?
     
    c = [self _bestComponentNameForName:c inContext:context];
    try {
        if (c && [c respondsToSelector:@SEL("Bindings")]) {
            var bd = [c Bindings];
            if (bd) {
                [WMLog debug:"Found Bindings() method in " + c];
                b = [[WMBindingDictionary new] initWithDictionary:bd];
            }
        }
    } catch (e) {
        [WMLog error:e];
    }
    

	//WM::Log::debug("Trying to load bindings at $fullPath");
	if (!b) {
    	try {
    		b = [[WMBindingDictionary new] initWithContentsOfFileAtPath:fullPath];
    		inheritanceContext[fullPath]++;
    	} catch (e) {
    		[WMLog error:e];
    	}
    }
	if (b) {
		bindings.push(b);
		
		//WM::Log::debug("^^^^^^^^^^^^ Checking for inheritance");
		if (b['inheritsFrom']) {
			var ancestor = b['inheritsFrom'];
			[WMLog debug:"^^^^^^^^^^^^^^ inherits from " + ancestor];
			if ([self pathIsSystemPath:ancestor]) {
				//ancestor =~ s/SYSTEM_COMPONENT_NAMESPACE\:\://;
			}
			//ancestor =~ s/::/\//g;

			// TODO bulletproof this... it would be possible and EASY to send this
			// into an infinite spin by having a loop in inheritance (binding A depends on
			// other bindings files that somehow depend on A)
			
            bindings.push([self bindingsForPath:ancestor inContext:context :inheritanceContext]);
		} else {

			// If there's no specific parent, we're at the root of the user-specified
			// inheritance tree, so we will suck in the default binding if it exists
			// making sure we don't get stuck in a resolution loop for the default binding
			// file too...
			var defaultBinding = [application configurationValueForKey:"DEFAULT_BINDING_FILE"];
			if (defaultBinding) {
                var dbre = new RegExp("/" + defaultBinding + ".bind");
                if (!fullPath.match(dbre)) {
                    [WMLog debug:"Sucking in default bindings " + defaultBinding];
				    bindings.push([self bindingsForPath:defaultBinding inContext:context :inheritanceContext]);
                }
			}
		}
	}
	return bindings;
}

+ componentForBinding:(id)binding inContext:(id)context {
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
	    return [cls newFromBinding:binding];
	}
	return nil;
}

+ (WMComponent) componentForName:(id)componentName andContext:(id)context {
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

+ (CPString) _bestComponentNameForName:(id)componentName inContext:(id)context {
	var application = context ? [context application] : [WMApplication defaultApplication];
	var componentNamespaces = [application configurationValueForKey:"COMPONENT_SEARCH_PATH"];
	var bestComponentPath;

    for (var i=0; i<componentNamespaces.length; i++) {
        var ns = componentNamespaces[i];
		var componentPath = ns + ""; // There's no namespace separator in Objj?  Or could we use a "."?
		if (![self pathIsSystemPath:ns] && [self componentPath]) {
			componentPath = componentPath + [self componentPath] + "";
		}
		componentPath = componentPath + componentName;
		
	    // unless ($COMPONENT_LOAD_ATTEMPTS->{$componentPath}) {
	    //          $COMPONENT_LOAD_ATTEMPTS->{$componentPath} = 1;
	    //          WM::Log::debug("Going to try $componentPath because we haven't yet");
	    //          my $load = eval "use $componentPath;";
	    //             if ($load) {
	    //                 WM::Log::debug("Successfully loaded module $componentPath");
	    //             }
	    //      }
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

+ (WMComponent) bestComponentForName:(id)componentName inContext:(id)context {
	var resolvedComponentName = [self _bestComponentNameForName:componentName inContext:context];
	if (resolvedComponentName) {
        var cls = objj_getClass(resolvedComponentName);
		return [cls new];
	} else {
		return nil;
	}
}

+ preferredLanguagesForTemplateResolutionInContext {
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
+ (Boolean) pathIsSystemPath:(id)path {
    if (!path) { return false }
    if (path.match(/^WMComponent/)) { return true }
}

@end
