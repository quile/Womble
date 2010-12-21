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

// TODO:kd - disentangle context and request

@import <WM/WMContext.j>
@import <WM/WMRequest.j>
@import <WM/WMLog.j>
@import <WM/WMException.j>

var logMask;
//var _componentNamespace;

var SESSION_STATUS_MESSAGES_KEY = "__statusMessages";

@implementation WMWebServerHandler : WMObject
{
}

//+ componentNamespaceInContext:(id)context {
//	if (!_componentNamespace) {
//		_componentNamespace = [context application]->configurationValueForKey("DEFAULT_NAMESPACE") + "::Component::";
//	}
//	return _componentNamespace;
//}

+ (WMContext) contextForRequest:(id)request {
	var context = [WMContext contextForRequest:request];
    if (!context) { return nil }

	// reinflate any saved status messages
	var session = [context session];
	var statusMessages = [session sessionValueForKey:SESSION_STATUS_MESSAGES_KEY];
	if (statusMessages && statusMessages.length) {
	    [context setStatusMessages:statusMessages];
	    [session setSessionValue:nil forKey:SESSION_STATUS_MESSAGES_KEY];
	}
	return context;
}

+ (void) startLoggingTransactionInContext:(id)context {
	[WMLog startLoggingTransaction:[context request]];
	// FIXME:kd - logMask should be threadsafe
    logMask = 0;
	[WMLog logQueryDictionaryFromContext:context]; // this will only log the qd if the mask is set to log it
}

+ (WMComponent) targetComponentForContext:(id)context {
	var targetComponentName = [context targetComponentName];
	var siteClassifier      = [context siteClassifier];
	return [siteClassifier componentForName:targetComponentName andContext:context];
}

// + (WMResponse) responseForComponentInContext:(id)context {
// 	return WMComponent.__responseFromContext(context);
// }

+ (void) allowComponent:(WMComponent)component toTakeValuesFromRequest:(id)context {
	// allow component to process incoming data
	[WMLog info:">>>>>>>>>>>>>>>> takeValuesFromRequest"];
	// This is a temporary hack to expose the context to the underlying
	// component machinery.  It's pointless insofar as the context is
	// passed in here; the problem is that there is legacy code that
	// expects to be able to find the context in self.context, and it
	// won't be set unless we push it in here:
    [component setContext:context];
	[component takeValuesFromRequest:context];
	[WMLog info:"<<<<<<<<<<<<<<<< takeValuesFromRequest"];
}

+ (id) actionResultFromComponent:(WMComponent)component inContext:(id)context {
	[WMLog info:">>>>>>>>>>>>>>>> direct action [" + [context directAction] + "]"];
	var result = [component invokeDirectActionNamed:[context directAction] inContext:context];
	[WMLog info:"<<<<<<<<<<<<<<<< direct action returned " + result];
	return result;
}

+ (id) allowComponent:(WMComponent)component toAppendToResponse:(id)response inContext:(id)context {
	[WMLog info:">>>>>>>>>>>>> appendToResponse() [ " + component + "]"];
	var result = [component appendToResponse:response inContext:context];

	// Send out the most recent session id as a cookie:
	if (![[context session] isNullSession]) {
		[context setSessionCookieValue:[[context session] externalId] forKey:[[context application] sessionIdKey]];
	}

	[WMLog info:"<<<<<<<<<<<<< appendToResponse()"];
	return result;
}

+ (id) handler:(id)lowLevelRequest {
	var context, request, response;
	var ERROR_CODE, ERROR_MSG;

	[WMLog debug:"=====================> Main handler invoked"];

	try {
		// generate a context for this request
        request = [WMRequest newFromRequest:lowLevelRequest];
		context = [self contextForRequest:request];
        [WMLog debug:"Inflated context: " + context];
		if (!context) {
            //[WMBadRequest raise:"WMBadRequest" reason:"Malformed URL: Failed to instantiate a context for request " + [request uri]];
            throw [[WMBadRequest alloc] initWithName:"WMBadRequest" reason:"Malformed URL: Failed to instantiate a context for request " + [request uri]];
		}

		// figure out what app and instance this is
		var application = [context application];
		if (!application) {
            //[WMInternalServerError raise:"WMInternalServerError" reason:"No application object found for request " + [request uri]];
            throw [[WMInternalServerError alloc] initWithName:"WMInternalServerError" reason:"No application object found for request " + [request uri]];
		}

		// Initialise the logging subsystem for this transaction
		[self startLoggingTransactionInContext:context];

        // Set the language for this transaction so the I18N methods
        // use the right strings.
        //[WMI18N setLanguage:[context language]];

		// figure out which component we're going to be running with
		var component = [self targetComponentForContext:context];
		if (!component) {
            //[WMInternalServerError raise:"WMInternalServerError" reason:"No component object found for request " + [request uri]];
            throw [[WMInternalServerError alloc] initWithName:"WMInternalServerError" reason:"No component object found for request " + [request uri]];
		}
		[WMLog info:" - " + [context urlWithQueryString]];

		// just before append to response begins, push the CURRENT request's
		// sid into the query dictionary in case any component (like AsynchronousComponent)
		// decides to fish around in there to build urls
		// [context queryDictionary]->{context->application()->sessionIdKey()} = context->session()->externalId();

		[self allowComponent:component toTakeValuesFromRequest:context];

		var actionResult = [self actionResultFromComponent:component inContext:context];

		// if we have a result from the action, set the component and the response
		// to be the appropriate objects
		if (actionResult) {
			if ([actionResult isKindOfClassNamed:"WMComponent"]) {
				[WMLog debug:"Action returned a component " + actionResult];
				component = actionResult;
                // FIXME:kd - unroll this and work it into renderWithParameters
				// var componentName = [component componentNameRelativeToSiteClassifier];
				// var templateName = [WMComponent __templateNameFromComponentName:componentName];
				response = [WMResponse new];
				// var template = [[context siteClassifier] bestTemplateForPath:templateName andContext:context];
				// [response setTemplate:template];
            } else if ([actionResult isKindOfClassNamed:"WMResponse"]) {
                // action returned a response; we have to assume it's fully populated and return it
                response = actionResult;
			} else {
				return [self redirectBrowserToAddress:actionResult inContext:context];
			}
		} else {
		    response = [component response];
		}

		// now we have component and response, no matter what the results of
		// the action were.
		if (actionResult != response) {
		    var responseResult = [self allowComponent:component toAppendToResponse:response inContext:context];
		    if (responseResult) {
			    return [self redirectBrowserToAddress:responseResult inContext:context];
		    }
		}

		if (logMask) {
			[WMLog endLoggingTransaction];
			[WMLog dumpLogForRequest:request usingLogMask:logMask];
		}

        // This sends the generated response back to the client:
		return [self returnResponse:response inContext:context];
	} catch (exception) {
        if (![exception isKindOfClass:WMException]) {
            exception = [[WMException alloc] initWithName:"WMException" reason:exception];
        }
        [WMLog error:exception];
        return exception;
    }

	if (ERROR_CODE) {
		[WMLog debug:ERROR_MSG];
		return ERROR_CODE;
	}
	//if ($@) {
	//	if (TRACE) {
	//		generateServerErrorPageForErrorInContextWithRequest(TRACE, context, r);
	//	} else {
	//		generateServerErrorPageForErrorInContextWithRequest($@, context, r);
	//	}
	//	WMLog clearMessageBuffer();
	//} else {
    return response;
	//}
}

+ (void) didRenderInContext:(id)context {
    if (![[context session] isNullSession]) {
        [[context session] save];
    }
	[WMLog clearMessageBuffer]; // just make sure it's empty
}

+ (id) redirectBrowserToAddressInContext:(id)context {
	// save any status messages to be relayed on the next request.  We have to
	// do it here before didRenderInContext is called, because that will
	// persist the session.
	var statusMessages = [context statusMessages];
	if (statusMessages && statusMessages.length) {
	    [[context session] setSessionValue:statusMessages forKey:SESSION_STATUS_MESSAGES_KEY];
	}

	// This is a bit of a cheat; if the redirect is actually code, execute it.
	// This allows us to pass things off to Apache if we really have to.
    /*
	if (ref(redirect) == "CODE") {
	    [className didRenderInContext:context];
	    return redirect->(context);
	}

	[className didRenderInContext:context];

	var r = [context request];

	[r content_type:context->contentType()](context->contentType());

	var serverHostName = [context application]->configurationValueForKey('SERVER_NAME');
	var serverPort = [context application]->configurationValueForKey('SERVER_PORT');
	if (serverPort != 80) {
		serverHostName .= ":" + serverPort;
	}
	if (redirect !~ /^https?:\/\/|mailto:/) {
		redirect = "http://" + serverHostName + redirect;
	}

	var cookieHeader = r->headers_out->{'Set-Cookie'};
	WMLog debug("Forcing redirect to redirect");
	// And make sure that the m#!$@rfracking dumbass
	// AOL cache doesn't store the wrong redirect
	// (hence the Cache-Control: no-store)
	if (cookieHeader != "") {
		[r send_cgi_header:<<EOH1](<<EOH1);
Set-Cookie: cookieHeader
EOH1
	}
	[r send_cgi_header:<<EOH](<<EOH);
Status: 303 Redirect
Content-type: text/html
Location: redirect
URI: redirect
Cache-Control: no-store

EOH
    */
	return OK;
}

+ (void) returnResponse:(id)response inContext:(id)context {
	[self didRenderInContext:context];
    return response;
    /*
	var r = [context request];
	var contentType = [response contentType] || [context contentType];
    [r setContentType:contentType];
	// allow a page to specify an error code via the context
	if (context && [context responseCode]) {
		//print STDERR "Response code: ".$context->responseCode(). " from context";
		[r status:context->responseCode()](context->responseCode());
	}
	if (context && [context cacheControlMaxAge]) {
		var cacheControl = "max-age=" + [context cacheControlMaxAge];
		//print STDERR "Cache-Control: $cacheControl from context\n";
		r->headers_out->{'Cache-Control'} = cacheControl;
		// never set cookies on pages that will be cached remotely
		var headers = [r err_headers_out];
		[headers unset:"Set-Cookie"]("Set-Cookie");
	} else {
		r->headers_out->{'Cache-Control'} = "no-store";
	}

	r->headers_out->{'Cache-Type'} = "text/html; charset=utf-8" unless [context contentType];
	if (MP1) {
		[r send_http_header];
	}
	[r print:response->content()](response->content());
	*/
}

/*
+ geneR:(id)r ateServerError:(id)error pageForErrorInContext:(id)context withRequest {
	var uri = [r uri];
	error = "<em>URI:</em> <code>uri</code><br /><br />\n" + error;

	eval {
		// we can't use the framework to generate the error
		// error page, because what if the error is in the framework?
		// so we have to check everything at each step...
		var logMask = WMLog logMaskFromContext(context, r);
		var errorTemplate;
		var appName = [r dir_config]->get("Application") || 'IF';
		var application = [IFApplication applicationInstanceWithName:appName];
		if (application) {
			errorTemplate = [application error:error pageForErrorInContext:context];
		} else {
			errorTemplate = error;
		}
		WMLog error(error);
		// better not assume we have a context ...
		[r content_type:'text/html']('text/html');
		[r status:SERVER_ERROR](SERVER_ERROR);
		if (MP1) {
			[r send_http_header];
		}
		[r print:errorTemplate](errorTemplate);
		// do this all over again here:
		if (logMask) {
			WMLog endLoggingTransaction();
			WMLog dumpLogForRequestUsingLogMask(r, logMask);
		}
	};

	//last chance
	if ($@) {
		WMLog error($@);
		[r content_type:'text/html']('text/html');
		if (MP1) {
			[r send_http_header];
		}
		[r print:$@]($@);
		WMLog clearMessageBuffer();
	};
}

// Borrowed from CGI::HMTLError with modifications
+ show_trace:(id)error {
	var (filename_from_stack,number_from_stack);

	//
	// now get the error string (we ignore exception objects, and just
	// pray they will be stringified to a useful string)
	//

	var (filename,number,rest_of_error);
	if (error =~ s/^( + *?\s+at\s+( + *?)\s+line\s+(\d+)[^\n]*)//s) {
		rest_of_error = error;
		error = 1;
		filename = 2;
		number = 3;
	}

	print STDERR "error - filename - number - rest_of_error - \n";

	//
	// If we haven't found the file and line in the string, just use
	// the one found in the stack-trace.
	//

	unless (filename) {
		filename = filename_from_stack;
		number = number_from_stack;
		rest_of_error .= "Exception caused at filename line number";
	}

	//
	// show stacktrace if a tracelevel is specified.
	//
	var trace;
	push trace, '<hr><em>Stacktrace:</em><pre><code>';
	var i;
	while (1) {
		var (pack,file,number,sub) = caller(i) or last;
		push trace, sprintf "%02d| \&sub called at file line number\n",i++;
	}
	push trace, '</code></pre>';

	var msg = join ('<br />', error, rest_of_error, trace);
	TRACE = msg;
}
*/

@end