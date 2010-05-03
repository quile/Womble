/* --------------------------------------------------------------------
 * IF - Web Framework and ORM heavily influenced by WebObjects & EOF
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

/*---------------------------------------
  The main Application class of an IF-
  based web application.
----------------------------------------*/

@import <Foundation/CPDictionary.j>
@import "Object.j"
@import "Log.j"
@import "Dictionary.j"

/* TODO: wtf to do with paths? */
//require.paths.unshift("conf");
//require.paths.unshift("IF/conf");

/* cache the app instances */
var _applications = [IFDictionary new];
var _defaultApplicationName;
var _environmentIsProduction;

//var SITE_CLASSIFIER_CLASS_FOR_NAME = [IFDictionary new];
//var _defaultSite;
var FILE = require('file');
var JSON = require('json');

@implementation IFApplication : IFObject
{
    CPString     namespace @accessors;
    CPString     _sessionIdKey;
    IFDictionary configuration;
    IFDictionary _modules;
}

+ _new:(id)ns {
    return [[super alloc] initWithNamespace:ns];
}

- (id) initWithNamespace:(id)ns {
    namespace = ns;
    _modules = [IFDictionary new];

	if (typeof self != "IFApplication") {
	    /* load config */
	    var config = [self configuration];
        [self init];
	    [self start];
	}
	return self;
}

- start {
	[self initialiseI18N];
}

+ contextClassName {
	return "IFContext";
}

+ sessionClassName {
	[IFLog error:"You MUST subclass IF::Session and override 'sessionClassName' in your application"];
	return null;
}

+ requestContextClassName {
	[IFLog error:"You MUST subclass IF::RequestContext and override 'requestContextClassName' in your application"];
	return null;
}

+ siteClassifierClassName {
	[IFLog error:"You MUST subclass IF::SiteClassifier and override 'siteClassifierClassName' in your application"];
	return null;
}

+ siteClassifierNamespace {
	[IFLog error:"You MUST subclass IF::SiteClassifier and override 'siteClassifierNamespace' in your application"];
	return null;
}

/* This is kind of arbitrary; override it in your app to determine whether or not the app
   is running in "production".
*/
- environmentIsProduction {
    return ([self configurationValueForKey:"ENVIRONMENT"] == "PROD");
}

+ applicationInstanceWithName:(id)applicationNameForPath {
	if (![_applications objectForKey:applicationNameForPath]) {
		/* this faults in the framework configuration if it hasn't
		   been loaded yet
		*/
        //[IFLog debug:"... application " + applicationNameForPath + " has not been loaded yet."];
		if (applicationNameForPath != "IF") {
			[IFApplication applicationInstanceWithName:"IF"];
			if (!_defaultApplicationName) {
				_defaultApplicationName = applicationNameForPath;
			}
		}
		var application;
		try {
			var applicationClassName = applicationNameForPath + "Application";
            var c = objj_getClass(applicationClassName);
			application = [c _new:applicationNameForPath];
		} catch (e) {
            [IFLog error:e];
        }
        if (!application) { return; }
		[_applications setObject:application forKey:applicationNameForPath];
		//[IFLog debug:"Loaded application configuration for " + applicationNameForPath];
		//[IFLog dump:[application configuration]];
	}
	return [_applications objectForKey:applicationNameForPath];
}

/* This doesn't apply any ordering to what's returned. */
+ allApplications {
    return [_applications values];
}

/* some shortcuts */
+ systemConfiguration {
	return [[IFApplication applicationInstanceWithName:"IF"] configuration];
}

+ systemConfigurationValueForKey:(id)key {
	return [[IFApplication systemConfiguration] objectForKey:key];
}

+ configurationValueForKey:(id)key inApplication:(id)applicationNameForPath {
	var application = [IFApplication applicationInstanceWithName:applicationNameForPath];
	if (!application) {
		[IFLog error:"Couldn't locate application instance named " + applicationNameForPath];
		return;
	}
	return [application configurationValueForKey:key];
}

/* These are primarily designed to support offline apps that
   load the framework outside of apache, and some legacy code
*/
+ defaultApplication {
	return [self applicationInstanceWithName:_defaultApplicationName];
}

+ defaultApplicationName {
	return _defaultApplicationName;
}

/*instance methods */

/* The app's name is its namespace. */
- name {
    return namespace;
}

- configurationValueForKey:(id)key {
	/* configuration will definitely return at least an empty dictionary */
	if ([self hasConfigurationValueForKey:key]) {
		return [[self configuration] objectForKey:key];
	}
	return [IFApplication systemConfigurationValueForKey:key];
}

- hasConfigurationValueForKey:(id)key {
    var keys = [[self configuration] allKeys];
	return [keys containsObject:key];
}

- configuration {
	if (!configuration) {
        //[IFLog debug:"Loading config for namespace " + namespace];
		var configurationClassName = FILE.path("./conf/" + [IFApplication configurationClassForNamespace:namespace]);
        var conf = require(configurationClassName.canonical());
		if (!conf) {
			configuration = [IFDictionary new];
		} else {
			configuration = [IFDictionary dictionaryWithJSObject:conf.CONFIGURATION];
            //[IFLog info:JSON.stringify(conf.CONFIGURATION)];
		}
	}
	return configuration;
}

+ configurationClassForNamespace:(id)namespace {
	return namespace + ".conf";
}

- errorPageForError:(id)error inContext:(id)context {
	return "<b>" + error + "</b>";
}

- redirectPageForUrl:(id)url inContext:(id)context {
	return "<b>" + url + "</b>";
}

/* This is used in error reporting and redirection.  The reason
   we do this is because if the system yacks and throws an error,
   the page that reports it needs to be able to load the error
   template *without* using the rendering framework, which
   could have caused the yacking in the first place.
*/
+ _returnTemplateContent:(id)fullPathToTemplate {
	[IFLog debug:"Trying to load " + fullPathToTemplate];
    var template = FILE.open(fullPathToTemplate, "r");
	if (template) {
		var templateFile = template.read();
		return templateFile;
	}
	return;
}

+ safelyLoadTemplateWithNameInContext:(id)context {
	if (!template) { return };
	var templateRoot = [self configurationValueForKey:"TEMPLATE_ROOT"];
	var language = context ? [context language] : [self configurationValueForKey:"DEFAULT_LANGUAGE"];

	var siteClassifier = "";
	if (context && [context siteClassifier]) {
		var sc = [context siteClassifier];
		while (sc) {
			siteClassifier = "/" + [sc path];
			var fullPathToTemplate = join("/", templateRoot + siteClassifier, language, template);
			var content = _returnTemplateContent(fullPathToTemplate);
			if (content) { return content };
			sc = [sc parent];
		}
	} else {
		var fullPathToTemplate = join("/", templateRoot, language, template);
		return _returnTemplateContent(fullPathToTemplate);
	}
	return "";
}

- cleanUpTransactionInContext:(id)context {
    /* override this in your subclass to perform post-transaction cleanup */
}

/* make sure the path is below the project root and does not
   contain any ..'s:
*/

+ pathIsSafe:(id)path {
    var re = /\.\./;
	if (re.test(path)) {
        return false;
    }
	var projectRoot = [self configurationValueForKey:"APP_ROOT"];
    re = new RegExp("^" + projectRoot);
    if (re.test(path)) {
        return true;
    }
	return false;
}

/* site classifier goo... disentangling SiteClassifiers
   from the context
   If you add a SiteClassifier instance class, you will
   need to restart your server, because this class caches the
   resolutions of mappings so it doesn't needlessly run the
   expensive require() operation on every request.
*/
/*

+ siteClassifierWithName:(id)name {
    var namespace = [self siteClassifierNamespace];
    var className = [self siteClassifierClassName];
    if (!IFLog.assert(className, "Site classifier classname implemented")) {
        return null;
    }

    // This loads it from the DB. Note that it's loaded as
    // a plain entity, then blessed into the right instance class.
    var sc = [className siteClassifierWithName:name];
    if (sc) {
        if (namespace) {
            var instanceClassName = namespace + "::" + [sc componentClassName];
            if (!SITE_CLASSIFIER_CLASS_FOR_NAME[name]) {
                var fn = instanceClassName;
                fn =~ s!::!/!g;
                fn .= " + pm";
                eval {
                    require fn;
                };
                if ($@) {
                    SITE_CLASSIFIER_CLASS_FOR_NAME[name] = className;
                } else {
                    SITE_CLASSIFIER_CLASS_FOR_NAME[name] = instanceClassName;
                }
            }
            if (!$@) {
                IFLog.debug("Site classifier being blessed into class SITE_CLASSIFIER_CLASS_FOR_NAME[name]");
                bless sc, SITE_CLASSIFIER_CLASS_FOR_NAME[name];
            }
        }
    } else {
        sc = [className defaultSiteClassifierForApplication:self->application()](self->application());
        if (!sc) {
            IFLog.error("Found neither Site Classifier: name".
            "  or a default classifier.  PROBABLE MIS-CONFIGURATION or DATABASE PROBLEMS");
            return;
        }
    }
    return sc;
}

- defaultSiteClassifier {
	if (!_defaultSite) {
        // blah blah _defaultSite = return [self siteClassifierClassName:[IFApplication defaultSiteClassifierForApplication:[self->application());
	}
	return _defaultSite;
}
*/

/* This will allow an application to interact with its modules */

/* You need to override this in your application */
- defaultModule {
	[IFLog error:"defaultModule method has not been overridden"];
	return null;
}

- modules {
	return [_modules allValues];
}

- moduleWithName:(id)name {
	return [_modules objectForKey:name];
}

- registerModule:(id)module {
	[IFLog debug:" `--> registering module " + [module name]];
    [_modules setObject:module forKey:[module name]];
}

- moduleInContext:(id)context forComponentNamed:(id)componentName {
    //for (module in _modules) {
	//	if ([module isOwnerInContext:context ofComponentNamed:componentName]) {
     //       return module;
      //  }
//	}
	[IFLog debug:"Returning default module for componentName"];
	return [self defaultModule];
}

- serverName {
	return [self configurationValueForKey:'SERVER_NAME'];
}

- initialiseI18N {
    /*
    [IFLog info:"Loading I18N modules"];
    var i18nDirectory = [self configurationValueForKey:"APP_ROOT"] + "/" + namespace + "/I18N"; # TODO make this configurable
    opendir DIR, i18nDirectory or return [IFLog info:" + .. No I18N found at i18nDirectory"];
    var files = grep /\ + pm$/, readdir(DIR);
    closedir(DIR);
    foreach var file (files) {
        IFLog.debug(" --> found language module file");
        file =~ s/\ + pm$//g;
        eval "use " + namespace + "::I18N::" + file;
        die ($@) if $@;
    }
    */
}

/* override this if you want to change the key */
- sessionIdKey {
    if (!_sessionIdKey) {
        _sessionIdKey = [[self name] lowerCaseString]  + "-sid";
    }
    return _sessionIdKey;
}

/* grab an instance of the mailer here.  You can use it to send mail, but you need to be sure that you
   have all the right bits set in your application's configuration.
*/
- mailer {
    /* defer loading of the mailer until now to make it easier for all the classes to load and initialise first. */
    //eval "use IFMailer;";
    //return self._mailer ||= [IFMailer new]->initWithApplication(self);
}

/* by default all addresses are UNSAFE.  you need to implement this in your
   application subclass so you can send email to people other than the
   site administrator.
*/
/*
+ emailAddress:(id)address isSafe {
	return 1 if (address == [self configurationValueForKey:"SITE_ADMINISTRATOR"]);
	return 0;
}
*/

/* TODO - rename this and group the mail-specific methods somehow.
   This needs help; we need to have some config directives with things like
   returned-mail address format, and the different types?
*/
/*
- createBounceAddressto :(id)from :(id)type {
	var bounceaddr;

	type = 'if' unless type;
	to =~ s/\@/\=/;
    // $bounceaddr = $type.'+'.$to.'@returnedmail.idealist.org';
    bounceaddr = type + '+' + to;

    return bounceaddr;
}
*/

- run {
    [self subclassResponsibility];
}

@end
