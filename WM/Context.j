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

// FIXME: the API for this class is bent, mostly because it evolved
// over years of patching and hacking.  Tidy it up!

@import "ObjectContext.j"
@import "Array.j"
//@import "Request.j"

var UTF = require("utf8");

//==============================
// This is used to indicate that the system should not
// create and save a session for this request, and instead
// just use a transient session.  It's used mostly in AJAX transactions.
var NULL_SESSION_ID = "x";

// TODO: implement with categories:
//    WMInterfaceKeyValueCoding
//    WMInterfaceStatusMessageHandling

@implementation WMContext : WMObject
{
    id _application;
    id _contentType;
    id _responseCode;
    id _cacheControlMaxAge;
    id _request;
    id _incomingCookies;
    id _formValues;
    id _queryDictionary;
    id _preferredLanguagesForTransactionAsToken;
    id _languagePreferences;
    id _lastRequestContext;
}

- (id) init {
    _contentType = "text/html";
    _responseCode = nil;
    _request = nil;
    _incomingCookies = {};
    _formValues = {};
    _queryDictionary = nil;
    return self;
}

// This is the real factory method for context objects.
// Nothing else should be used to create them.
//
//  request is a descendant of WMRequest
+ contextForRequest:(id)request {
    // grab the application instance:
    var application = [WMApplication applicationInstanceWithName:[request applicationName]];
    var cl = [self class];
    if (application) {
        className = [[application class] contextClassName];
        if (className) {
            cl = objj_getClass(className);
        }
    }

    // instantiate the context
    var context = [cl new];
    [context setRequest:request];

    // inflate the context from the URI etc.
    if (![context inflateContextFromRequest]) {
        [WMLog error:"Malformed URL: couldn't parse - " + [request uri]];
        return nil;
    }

    // set the order of preferred languages for this user
    [context setLanguagePreferences:[context browserLanguagePreferences]];

    // derive language preferences for this transaction
//    if ($context->formValueForKey("LANGUAGE")) {
//        # check for multiple values here (2003-10-27)
//        my $values = $context->formValuesForKey("LANGUAGE");
//        if ($values && scalar @$values) {
//            # default to the first one TODO: fix this!
//            $context->setLanguage($values->[0]);
//        } else {
//            $context->setLanguage($context->formValueForKey("LANGUAGE"));
//        }
//    } elsif ($context->cookieValueForKey("LANGUAGE")) {
//        $context->setLanguage($context->cookieValueForKey("LANGUAGE"));
//    } elsif ($ENV{'LANGUAGE'}) {
//        $context->setLanguage($ENV{'LANGUAGE'});
//    } else {
//        my $languagePreferences = $context->languagePreferences();
//        $context->setLanguage($languagePreferences->[0]);
//    }

    return context;
}

+ applicationName {
    return [WMApplication defaultApplicationName];
}
// ...except this, used for off-line generation of
// contexts
+ emptyContext {
    return [self emptyContextForApplicationWithName:[self applicationName]];
}

+ emptyContextForApplicationWithName:(id)appName {
    var emptyContext =  [self new];
    [emptyContext setRequest:[WMRequest new]];
    [[emptyContext request] setApplicationName:appName];
    [emptyContext setSession:[emptyContext newSession]];
    return emptyContext;
}

//  lang will match fr and fr_ca style languages
- inflateContextFromRequest {
    var uri = [[self request] uri];

    [WMLog debug:"Parsing URI: " + uri];

    var ure = new RegExp("^/([A-Za-z0-9]+)/([A-Za-z0-9-]+)/([A-Za-z0-9_]+)/(.+)/([A-Za-z0-9\.-]+)");
    var match = uri.match(ure);
    var all = match[0];
    var adaptor = match[1];
    var site = match[2];
    var lang = match[3];
    var component = match[4];
    var action = match[5];
    if (!action) { return false }
    var bits = _p_2_split("-", action);
    var targetPageContextNumber = bits.shift();
    var directActionName = bits.shift();

    [WMLog debug:"- Adaptor: " + adaptor];

    [self setLanguage:lang];
    [WMLog debug:"- Language: lang"];

    [self setSiteClassifierByName:site];

    // If we didn't even find a default SC, bail, we're toast.  This only happens in a mis-configured setup
    if (![self siteClassifier]) { return false }
    [WMLog debug:"- Site Classifier Name: " + site];

    //component =~ s#/#::#g;
    [self setTargetComponentName:component];
    [WMLog debug:"- Component: " + component];

    [self buildFormValueDictionaryFromRequest];

    // check for an action indicated by a button code:
    var keys = [self formKeys];
    for (var i=0; i<keys.length; i++) {
        var param = keys[i];
        //WM::Log::debug("Checking request for direct action declared in param $param");
        if (!param.match(/^_ACTION:?/)) { continue }
        action = param;
        action = action.replace(/.*\//g, "");
        if (targetPageContextNumber && targetPageContextNumber.match(/^[0-9_]+$/)) {
            action = [targetPageContextNumber, action].join("-");
        }
        break;
    }

    [self setDirectAction:action];
    [WMLog debug:"- Direct Action: " + action];

    // inflate the session
    var cl = [self class];
    [self setSession:[cl sessionFromContext:self]];

    [WMLog debug:"Session is " + [self session] + " and has external id " + [[self session] externalId]];
    return true;
}

// FIXME: mod_perl needed this, but I doubt we
// need it in objj.
- (void) buildFormValueDictionaryFromRequest {
    var keys = [[self request] formKeys];
    for (var i=0; i<keys.length; i++) {
        var key = keys[i];
        var values = [WMArray arrayFromObject:[_request formValueForKey:key]];
        var decodedValues = [];
        for (var j=0; j<values.length; j++) {
            var value = values[j];
            var decodedValue = UTF8.decode(value);
            decodedValues.push(decodedValue || value);
        }
        _formValues[key] = decodedValues;
        // TODO we used to strip incoming values for
        // common xss tricks here; bad form but it was
        // a quick fix.
        //v =~ s/<[^>]*script[^>]*>/xss/gio;
        //v =~ s/document\s*\ + \s*cookie/xss/gio;
    }
}

- (WMRequest) request {
    return _request;
}

- (void) setRequest:(WMRequest)value {
    _request = value;
}

- newSession {
    var sessionClassName = [[[self application] class] sessionClassName];
    if (!sessionClassName) {
        throw [CPException raise:"CPException" reason:"No session class name found in application"];
    }
    var sc = objj_getClass(sessionClassName);
    var session = [sc new];
    [session setApplication:[self application]];
    return session;
}

- (WMSession) session { return _session }
- (void) setSession:(WMSession)s { _session = s }

/*
+ escape:(id)value {
    return CGI::escape(value);
}

+ unescape:(id)value {
    return CGI::unescape(value);
}
*/

- (id) cookies { return _cookies }
- (id) cookieValueForKey:(id)key {
    //WM::Log::dump($self->{_cookies});
    var cookie = [[self request] cookieValueForKey:key];
    if (!cookie) { return nil }
    // TODO: unescape cookies!
    var value = UTF8.decode([cookie value]);
    [WMLog debug:"======= got back cookie value " + value + " for " + key + " ========"];
    return value;
}

// FIXME: make the default cookie length be configurable via the app config
- (void) setCookieValue:(id)value forKey:(id)key {
    [self setCookieValue:value forKey:key withTimeout:"+12M"];
}

- setCookieValue:(id)value forKey:(id)key withTimeout:(id)timeout {
    [WMLog debug:"======= set cookie value: " + value + " for key: " + key + " ========"];
    // TODO: add cookies to Request
    /*
    var newCookie = [self request]->dropCookie(
                                    -name: key,
                                    -value: [self escape:value],
                                    -path: "/",
                                    -expires: timeout,
                                    );
    */
}

// TODO: the cookie API needs work...
- (void) setSessionCookieValue:(id)value forKey:(id)key {
    //WM::Log::debug("======= set session cookie value: $value for key: $key ========");
    /*
    var newCookie = [self request]->dropCookie(
                                    -name: key,
                                    -value: [self escape:value],
                                    -path: "/",
                                    );
    */
}

- (id) formValueForKey:(id)key {
    var values = [self formValuesForKey:key];
    if (values.length == 1) { return values[0] }
    return values;
}

- (id) headerValueForKey:(id)key {
    if (![self request]) { return nil }
    return [[self request] headerForKey:key];
}

- (void setHeaderValue:(id)value forKey:(id)key {
    if (![self request]) { return nil }
    // TODO: store the out-going headers in the context somewhere
    // to be fished out by the response later.
    //[self request]->headers_out->{key} = value;
}

/* TODO: implement uploads via the Request obj
- (id) uploadForKey:(id)key {
    return [[self request] uploadForKey:key];
}
*/

//  don't allow this any more if possible
- (void) setFormValue(id)value forKey:(id)key {
    _queryDictionary = nil;
    _formValues[key] = [WMArray arrayFromObject:value];
}

- (id) formValuesForKey:(id)key {
    return _formValues[key] || [];
}

- (id) formKeys {
    return _p_keys(_formValues);
}

- queryDictionary {
    if (!_queryDictionary) {
        var qd = {};
        var fks = [self formKeys];
        for (var i=0; i < fks.length; i++) {
            var key = fks[i];
            var values = [self formValuesForKey:key];
            //var value = [self formValueForKey:key];
            //if ([WMArray isArray:values] && values.length > 1) {
                qd[key] = values;
            //} else {
            //    qd[key] = value;
           // }
        }
        _queryDictionary = qd;
    }
    return _queryDictionary;
}

// And this is to transparently manipulate pnotes

- (void) setTransactionValue:(id)value forKey:(id)key {
    _request.env['womble.pnotes'] = _request.env['womble.pnotes'] || {};
    _request.env['womble.pnotes'][key] = value;
}

- (id) transactionValueForKey:(id)key {
    if (!_request.env['womble.pnotes']) { return nil }
    return _request.env['womble.pnotes'][key];
}

// this allows parts of the request to set up code references
// that clean up the transaction or perform long-running goo
// after the response has been sent back.
- (id) transactionCleanupRequests {
    return [self transactionValueForKey:"_cleanupRequests"] || [];
}

- (void) addTransactionCleanupRequest:(id)cr {
    var trs = [self transactionCleanupRequests];
    trs.push(cr);
    [self setTransactionValue:trs forKey:"_cleanupRequests"];
}

- (id) language {
    return _language;
}

- (void) setLanguage:(id)l {
    _language = l;
    [WMLog debug:"Setting language to " + _language];
    _preferredLanguagesForTransactionAsToken = null;
}

- (id) browserLanguagePreferences {
    var languagePreferences = [];
    /*
    // pull language preferences from headers
    foreach var language (split (/[ ]/, [self request]->headers_in->{'Accept-Language'})) {
        push (@languagePreferences, language);
    }

    // failover case:
    push (@languagePreferences, [self application]->configurationValueForKey("DEFAULT_LANGUAGE"));
    */

    //NOTE!  THIS IS JUST TEMPORARY!  IT MUST BE REMOVED WHEN LANGUAGES
    //PREFERENCES ARE SWITCHED ON
    languagePreferences = ["en"];
    //END OF TEMPORARY FIX

    return languagePreferences;
}

- (id) languagePreferences {
    return _languagePreferences;
}

- (void) setLanguagePreferences:(id)value {
    _languagePreferences = value;
}

- (id) directAction {
    return _directAction;
}

- (void) setDirectAction:(id)value {
    _directAction = value;
}

- (id) targetComponentName {
    return _targetComponentName;
}

- (void) setTargetComponentName:(id)value {
    _targetComponentName = value;
}

- (id) siteClassifier {
    return _siteClassifier;
}

- (void) setSiteClassifier:(id)value {
    _siteClassifier = value;
}

- (CPString) siteClassifierName {
    if (!_siteClassifier) { return nil }
    return [_siteClassifier name];
}

// Not too happy with the name of this method...

- (void) setSiteClassifierByName:(id)name {
    var sc = [[[self application] class] siteClassifierWithName:name];
    if (!sc) {
        throw [CPException raise:"CPException" reason:"Couldn't find site classifier " + name];
    }
    [self setSiteClassifier:sc];
}

- (Boolean) isCorrectRequestForContextNumber {
    [WMLog debug:"Incoming context number is " + [self contextNumber] + " and current context number is " + [[self session] contextNumber]];
    return [[self session] contextNumber] == ([self contextNumber] + 1);
}

- (Boolean) lastRequestWasSpecified {
    if ([self contextNumber]) { return true }
    return false;
}

- lastRequestContext {
    if (![self lastRequestWasSpecified]) { return nil }
    if (![self session]) { return nil }
    _lastRequestContext = _lastRequestContext || [[self session] requestContextForContextNumber:[self contextNumber]];
    return _lastRequestContext;
}

- (id) callingComponentPageContextNumber {
    return _callingComponentPageContextNumber;
}

- (void) setCallingComponentPageContextNumber:(id)value {
    _callingComponentPageContextNumber = value;
}

- (id) callingComponentId {
    return [self formValueForKey:"calling-component-id"];
}

// ------ some useful web-related goop ----

- (id) contentType {
    return _contentType;
}

- (void) setContentType:(id)value {
    _contentType = value;
}

// undef == OK
- (id) responseCode {
    return _responseCode;
}

- (void) setResponseCode:(id)value {
    _responseCode = value;
}

// when undef, the header is not set
- (id) cacheControlMaxAge {
    return _cacheControlMaxAge;
}

- (void) setCacheControlMaxAge:(id)value {
    _cacheControlMaxAge = value;
}

- (id) userAgent {
    return [self headerValueForKey:"User-Agent"];
}

- (id) referrer {
    return [self headerValueForKey:"Referer"];
}

- (id) contextNumber {
    return [self formValueForKey:"context-number"];
}

- (id) url {
    return [[self request] uri];
}

- (id) urlWithQueryString {
    return [[self request] uri] + '?' + [[self request] queryString];
}

- (WMApplication) application {
    if (!_application) {
        _application = [WMApplication applicationInstanceWithName:[[self request] applicationName]];
        if (!_application) {
            throw [CPException raise:"CPException" reason:"Application cannot be determined from context"];
        }
    }
    return _application;
}

// languageToken - used by WMComponent in matching templates to contexts
- (id) preferredLanguagesForTransactionAsToken {
    if (_preferredLanguagesForTransactionAsToken) { return _preferredLanguagesForTransactionAsToken }

    var siteClassifier = [self siteClassifier];
    var token;

    if (siteClassifier) {
        var scLangPreference = [siteClassifier preferredLanguagesForTemplateResolutionInContext:self];
        token = scLangPreference.join(":");
    }

    if (!token) {
        // 1. base language preference
        token = [self language];

        // 2. site classifier default language site
        if ([siteClassifier defaultLanguage] &&
            ([siteClassifier defaultLanguage] != [self language])) {
            token = token + ":" + [siteClassifier defaultLanguage];
        }

        // 3. any other preferred langs that site classifier has
        if (siteClassifier) {
            for (var i=0; i < [[self languagePreferences] count]; i++) {
                var language = [[self languagePreferences] objectAtIndex:i];
                if ([siteClassifier hasLanguage:language] && language != [siteClassifier defaultLanguage]) {
                    token = token + ":" + language;
                }
            }
        } else {
            token = token + ':' + [[self languagePreferences] componentsJoinedByString:':'];
        }
    }

    _preferredLanguagesForTransactionAsToken = token;
    return token;
}

- (id) preferredLanguagesForTransaction {
    return [self preferredLanguagesForTransactionAsToken].split(":");
}

// override this method to perform other cleanups
- (void) didGenerateResponse:(id)response {
    [[self session] save];
}

+ sessionFromContext:(id)context {
    var session;
    var sessionId;

    var application = [context application];
    var sessionClass = objj_getClass([[application class] sessionClassName]);

    //WMDB.dbConnection()->releaseDataSourceLock();

    // check for a SID
    var externalId = [context formValueForKey:[application sessionIdKey]] || [context cookieValueForKey:[application sessionIdKey]];

    if (externalId && externalId != NULL_SESSION_ID) {
        // check for a context-number
        var contextNumber = [context contextNumber];
        [WMLog debug:"Context number is " + contextNumber];
        if (contextNumber) {
            session = [sessionClass sessionWithExternalId:externalId andContextNumber:contextNumber];
        }

        if (!session) {
            session = [sessionClass sessionWithExternalId:externalId];
        } else {
            //[WMLog dump:session];
        }

        if (!session || (session && [session hasExpired])) {
            [WMLog debug:"!!! Session has expired, deleting it + "];
            // if we reach this point and still have no session, it means
            // a) the session has been deleted
            // b) funny business going on
            // so we desperately need to flush the cookies for the client-side
            // auth to work correctly
            //delete _incomingCookies[[application sessionIdKey]];
            [context setSessionCookieValue:"" forKey:[application sessionIdKey]];
            if (session) {
                [session becomeInvalidated];
                session = nil;
            }
        }
    }

    if (session) {
        [session wasInflated];
        return session;
    }

    // create new session
    session = [context newSession];

    if (!session) {
        // it's no longer considered an error to have no session
        // at this point.
        //[WMLog error:"Error creating new session"];
        return nil;
    }
    [WMLog debug:"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  created new session"];

    // TODO header case?  can it be mixed case like this? We could grab the ip from the jack request
    if ([context headerValueForKey:"X-Forwarded-For"]) {
        [session setClientIp:[context headerValueForKey:"X-Forwarded-For"]];
    }

    // save the new session
    //[WMLog debug:"External id is " + externalId];
    if (externalId == NULL_SESSION_ID) {
        [session _setExternalId:NULL_SESSION_ID];
        //[WMLog debug:"Set external session id to " + [session externalId]];
    } else {
        [session save];
        [WMLog debug:"Created session with external ID " + [session externalId]];
        //delete _incomingCookies[[application sessionIdKey]];
        [context setSessionCookieValue:[session externalId] forKey:[application sessionIdKey]];
    }

    return session;
}

+ NULL_SESSION_ID {
    return NULL_SESSION_ID;
}

// ------------- these messages are conveniences for accumulating status messages ------------

/*
+ addInfoMessage:(id)message {
    [self addInfoMessageInLanguage:message, self->language()](message, self->language());
}

+ addConfirmationMessage:(id)message {
    [self addConfirmationMessageInLanguage:message, self->language()](message, self->language());
}

+ addWarningMessage:(id)message {
    [self addWarningMessageInLanguage:message, self->language()](message, self->language());
}

+ addErrorMessage:(id)message {
    [self addErrorMessageInLanguage:message, self->language()](message, self->language());
}
*/

@end
