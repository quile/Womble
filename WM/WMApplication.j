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

/*---------------------------------------
  The main Application class of an WM-
  based web application.
----------------------------------------*/

@import <Foundation/CPDictionary.j>
@import "WMObject.j"
@import "WMLog.j"
@import "WMDictionary.j"
@import "WMSiteClassifier.j"

/* cache the app instances */
var _applications = [WMDictionary new];
var _defaultApplicationName;
var _environmentIsProduction;

//var SITE_CLASSWMIER_CLASS_FOR_NAME = [WMDictionary new];
//var _defaultSite;
var FILE = require('file');
var JSON = require('json');

@implementation WMApplication : WMObject
{
    CPString     namespace @accessors;
    CPString     _sessionIdKey;
    WMDictionary configuration;
    WMDictionary _modules;
    WMSiteClassifier _defaultSite;
}

+ (id) _new:(id)ns {
    return [[super alloc] initWithNamespace:ns];
}

+ (id) contextClassName {
    return "WMContext";
}

+ sessionClassName {
    [WMLog error:"You MUST subclass WM::Session and override 'sessionClassName' in your application"];
    return null;
}

+ requestContextClassName {
    [WMLog error:"You MUST subclass WM::RequestContext and override 'requestContextClassName' in your application"];
    return null;
}

+ siteClassifierClassName {
    [WMLog error:"You MUST subclass WM::SiteClassifier and override 'siteClassifierClassName' in your application"];
    return null;
}

+ siteClassifierNamespace {
    [WMLog error:"You MUST subclass WM::SiteClassifier and override 'siteClassifierNamespace' in your application"];
    return null;
}

- (void) start {
    [self initialiseI18N];
}

/* This is kind of arbitrary; override it in your app to determine whether or not the app
   is running in "production".
*/
- environmentIsProduction {
    return ([self configurationValueForKey:"ENVIRONMENT"] == "PROD");
}

- (id) initWithNamespace:(id)ns {
    namespace = ns;
    _modules = [WMDictionary new];

    if (typeof self != "WMApplication") {
        /* load config */
        var config = [self configuration];
        [self init];
        [self start];
    }
    return self;
}

+ applicationInstanceWithName:(id)applicationNameForPath {
    if (![_applications objectForKey:applicationNameForPath]) {
        /* this faults in the framework configuration if it hasn't
           been loaded yet
        */
        //[WMLog debug:"... application " + applicationNameForPath + " has not been loaded yet."];
        if (applicationNameForPath != "WM") {
            [WMApplication applicationInstanceWithName:"WM"];
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
            [WMLog error:e];
            throw e;
        }
        if (!application) { return; }
        [_applications setObject:application forKey:applicationNameForPath];
        //[WMLog debug:"Loaded application configuration for " + applicationNameForPath];
        //[WMLog dump:[application configuration]];
    }
    return [_applications objectForKey:applicationNameForPath];
}

/* This doesn't apply any ordering to what's returned. */
+ (id) allApplications {
    return [_applications values];
}

/* some shortcuts */
+ (id) systemConfiguration {
    return [[WMApplication applicationInstanceWithName:"WM"] configuration];
}

+ (id) systemConfigurationValueForKey:(id)key {
    return [[WMApplication systemConfiguration] objectForKey:key];
}

+ (id) configurationValueForKey:(id)key inApplication:(id)applicationNameForPath {
    var application = [WMApplication applicationInstanceWithName:applicationNameForPath];
    if (!application) {
        [WMLog error:"Couldn't locate application instance named " + applicationNameForPath];
        return;
    }
    return [application configurationValueForKey:key];
}

/* These are primarily designed to support offline apps that
   load the framework outside of apache, and some legacy code
*/
+ (id) defaultApplication {
    return [self applicationInstanceWithName:_defaultApplicationName];
}

+ (id) defaultApplicationName {
    return _defaultApplicationName;
}

/*instance methods */

/* The app's name is its namespace. */
- (id) name {
    return namespace;
}

- (id) configurationValueForKey:(id)key {
    /* configuration will definitely return at least an empty dictionary */
    if ([self hasConfigurationValueForKey:key]) {
        return [[self configuration] objectForKey:key];
    }
    return [WMApplication systemConfigurationValueForKey:key];
}

- (id) hasConfigurationValueForKey:(id)key {
    var keys = [[self configuration] allKeys];
    return [keys containsObject:key];
}

- (id) configuration {
    if (!configuration) {
        //[WMLog debug:"Loading config for namespace " + namespace];
        var configurationClassName = FILE.path("./conf/" + [WMApplication configurationClassForNamespace:namespace]);
        var conf = require(configurationClassName.canonical());
        if (!conf) {
            configuration = [WMDictionary new];
        } else {
            configuration = [WMDictionary dictionaryWithJSObject:conf.CONFIGURATION];
            //[WMLog info:JSON.stringify(conf.CONFIGURATION)];
        }
    }
    return configuration;
}

+ (id) configurationClassForNamespace:(id)namespace {
    return namespace + ".conf";
}

- (id) errorPageForError:(id)error inContext:(id)context {
    return "<b>" + error + "</b>";
}

- (id) redirectPageForUrl:(id)url inContext:(id)context {
    return "<b>" + url + "</b>";
}

/* This is used in error reporting and redirection.  The reason
   we do this is because if the system yacks and throws an error,
   the page that reports it needs to be able to load the error
   template *without* using the rendering framework, which
   could have caused the yacking in the first place.
*/
+ (id) _returnTemplateContent:(id)fullPathToTemplate {
    [WMLog debug:"Trying to load " + fullPathToTemplate];
    var template = FILE.open(fullPathToTemplate, "r");
    if (template) {
        var templateFile = template.read();
        return templateFile;
    }
    return;
}

+ (id) safelyLoadTemplateWithNameInContext:(id)context {
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

- (id) cleanUpTransactionInContext:(id)context {
    /* override this in your subclass to perform post-transaction cleanup */
}

/* make sure the path is below the project root and does not
   contain any ..'s:
*/

+ (id) pathIsSafe:(id)path {
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

+ (id) siteClassifierWithName:(id)n {
    var namespace = [self siteClassifierNamespace];
    var className = [self siteClassifierClassName];
    [WMLog debug:"SC info: " + namespace + " / " + className + " looking for " + n];
    if (![WMLog assert:className message:"Site classifier " + className + " implemented"]) {
        return nil;
    }

    var c = objj_getClass(className) || objj_getClass("WMSiteClassifier");
    if (c) {
        return [c siteClassifierWithName:n];
    }
    [WMLog error:"Couldn't load site classifier: " + n];
    return nil;
}

- (id) defaultSiteClassifier {
    if (!_defaultSite) {
        [WMLog debug:"Loading default site classifier"];
        var c = [self class];
        [WMLog debug:"... class is " + c];
        _defaultSite = [c siteClassifierWithName:"root"];
    }
    return _defaultSite;
}

/* This will allow an application to interact with its modules */

/* You need to override this in your application */
- (id) defaultModule {
    [WMLog error:"defaultModule method has not been overridden"];
    return null;
}

- (id) modules {
    return [_modules allValues];
}

- (id) moduleWithName:(id)name {
    return [_modules objectForKey:name];
}

- (void) registerModule:(id)module {
    [WMLog debug:" `--> registering module " + [module name]];
    [_modules setObject:module forKey:[module name]];
}

- (id) moduleInContext:(id)context forComponentNamed:(id)componentName {
    //for (module in _modules) {
    //    if ([module isOwnerInContext:context ofComponentNamed:componentName]) {
     //       return module;
      //  }
//    }
    [WMLog debug:"Returning default module for componentName"];
    return [self defaultModule];
}

- (id) serverName {
    return [self configurationValueForKey:'SERVER_NAME'];
}

- (id) initialiseI18N {
    /*
    [WMLog info:"Loading I18N modules"];
    var i18nDirectory = [self configurationValueForKey:"APP_ROOT"] + "/" + namespace + "/I18N"; # TODO make this configurable
    opendir DIR, i18nDirectory or return [WMLog info:" + .. No I18N found at i18nDirectory"];
    var files = grep /\ + pm$/, readdir(DIR);
    closedir(DIR);
    foreach var file (files) {
        WMLog.debug(" --> found language module file");
        file =~ s/\ + pm$//g;
        eval "use " + namespace + "::I18N::" + file;
        die ($@) if $@;
    }
    */
}

/* override this if you want to change the key */
- (id) sessionIdKey {
    if (!_sessionIdKey) {
        _sessionIdKey = [[self name] lowercaseString]  + "-sid";
    }
    return _sessionIdKey;
}

/* grab an instance of the mailer here.  You can use it to send mail, but you need to be sure that you
   have all the right bits set in your application's configuration.
*/
- (id) mailer {
    /* defer loading of the mailer until now to make it easier for all the classes to load and initialise first. */
    //eval "use WMMailer;";
    //return self._mailer ||= [WMMailer new]->initWithApplication(self);
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

- (id) run {
    [self subclassResponsibility];
}

@end
