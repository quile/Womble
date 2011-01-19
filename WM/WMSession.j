
@import <WM/WMObject.j>

@implementation WMSession : WMObject
{
    id _id @accessors(property=id);
    id _lastActiveDate @accessors(property=lastActiveDate);
    id _clientIp @accessors(property=clientIp);
    id _contextNumber  @accessors(property=contextNumber);
    id _requestContextOffset @accessors(property=requestContextOffset);
    id _application @accessors(property=application);
    id _requestContextClassName @accessors(property=requestContextClassName);
    id _externalId @accessors(property=externalId);
}

- (id) application {
    if (_application) {
        return _application;
    }
	return [WMApplication defaultApplication]; // Hokey but saves it from yacking
}

- (id) requestContextClassName {
    if (_requestContextClassName == nil) {
        [[self application] requestContextClassName];
    }
    return _requestContextClassName;
}

// This should be overridden in your subclass to
// create an external id if there isn't one
- (id) externalId {
	return _externalId;
}

// this is private API because only the fw should be
// setting this.
- (Boolean) _setExternalId:(id)value {
    _externalId = value;
}

- (void) isNullSession {
	return (_externalId == [WMContext NULL_SESSION_ID]);
}

- (Boolean) wasInflated {
}

- (Boolean) hasExpired {
    // basic implementation just checks dates
    var timeout = [[self application] configurationValueForKey:"DEFAULT_SESSION_TIMEOUT"];
    //var now = CORE::time();
    //var last = [IFGregorianDate new:self->lastActiveDate()](self->lastActiveDate());
    //return (now - timeout > [last utc]);
}

- (void) becomeInvalidated {
    [WMLog error:"WMSession becomeInvalidated not implemented"];
}

// TODO - fix this API!  This is a lame way to do it;
// it's either yea or nay like this, whereas it should
// be fine-grained.
+ userCanViewAdminPages {
    return 0;
}

// NOTE: These are a NOP for DB-based sessions unless you implement
// them yourself with some kind of session store.
- (void) setSessionValue:(id)value forKey:(id)key {
    return;
}

- (id) sessionValueForKey:(id)key {
    return nil;
}

@end