@import <WM/WMApplication.j>
@import <WM/Default/WMDefaultApplication.j>
@import <WM/WMLog.j>
@import <WM/WMObject.j>

@import "Model.j"

@import "Classes.j"
objj_msgSend_decorate(objj_backtrace_decorator);

// Modules
var _application;

@implementation WMTestApplication : WMDefaultApplication
{
}

//use WMTest::Module::Twang;
//use WMTest::Module::Bong;

/* Uncomment if any app-specific launch goo is needed
- init {
    [super init];
    return self;
}
*/

+ sessionClassName {
  return "WMTestSession";
}

+ requestContextClassName {
  return "WMTestRequestContext";
}

+ siteClassifierClassName {
  return "WMTestSiteClassifier";
}

+ siteClassifierNamespace {
    return "WMTestSiteClassifier";
}

+ defaultModelClassName {
    return "WMTestModel";
}

// This is at the application level so that the mailer
// can invoke it whenever it sends an email.  You can
// customise your behaviour here for sanitising
// outgoing email messages
- emailAddressIsSafe:(id)address {
    if (address == "banana\@banana.foz") { return true; }
    return [super emailAddressIsSafe:address];
}

/*
- application {
	if (!_application) {
		_application = [WMApplication applicationInstanceWithName:@"WMTest"];
	}
	return _application;
}
*/

- run {
    [WMLog info:"Test app started"];
}


@end

// This loads the application and its config
_application = [WMApplication applicationInstanceWithName:@"WMTest"];
