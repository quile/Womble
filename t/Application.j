@import <IF/Application.j>
@import <IF/Default/Application.j>
@import <IF/Log.j>
@import <IF/Object.j>

@import "Model.j"

@import "Classes.j"
objj_msgSend_decorate(objj_backtrace_decorator);

// Modules
var _application;

@implementation IFTestApplication : IFDefaultApplication
{
}

//use IFTest::Module::Twang;
//use IFTest::Module::Bong;

- init {
    [super init];
    return self;
}

- sessionClassName {
  return "IFTestEntitySession";
}

- requestContextClassName {
  return "IFTestEntityRequestContext";
}

- siteClassifierClassName {
  return "IFTestEntitySiteClassifier";
}

- siteClassifierNamespace {
    return "IFTestEntitySiteClassifier";
}

- defaultModelClassName {
    return "IFTestModel";
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
		_application = [IFApplication applicationInstanceWithName:@"IFTest"];
	}
	return _application;
}
*/

- run {
    [IFLog info:"Test app started"];
}


@end

// This loads the application and its config
_application = [IFApplication applicationInstanceWithName:@"IFTest"];
