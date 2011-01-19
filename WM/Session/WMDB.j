@implementation IFSessionDB : IFEntityPersistentIFSession {

// implements the DB-based persistence of sessions
@import <strict>;
use base qw(
    IFEntityPersistent
    IFSession
);

//--------------- Class Methods --------------------

+ sessionWithExternalId {
	IFLog.error("sessionWithExternalId() not overridden in Session subclass");
}

+ sessionWithExternalIdAndContextNumber {
	IFLog.error("sessionWithExternalIdAndContextNumber() not overridden in Session subclass");
}

+ sessionWithId {
	IFLog.error("sessionWithId() not overridden in Session subclass");
}

+ sessionWithIdAndContextNumber {
	IFLog.error("sessionWithIdAndContextNumber() not overridden in Session subclass");
}

+ externalIdRegularExpression {
	IFLog.error("externalIdRegularExpression() not overridden in Session subclass");
}

+ sessionWithExternalIdIsAuthenticated {
	IFLog.error("sessionWithExternalIdIsAuthenticated() not overridden in Session subclass");
}


//--------------- Core Methods --------------------

- lastActiveDate {
	return [self storedValueForKey:"lastActiveDate"]("lastActiveDate");
}

- setLastActiveDate:(id)value {
	[self setStoredValueForKey:value, "lastActiveDate"](value, "lastActiveDate");
}

- contextNumber {
	return [self storedValueForKey:"contextNumber"]("contextNumber");
}

- setContextNumber:(id)value {
	IFLog.stack(4);
	[self setStoredValueForKey:value, "contextNumber"](value, "contextNumber");	
}

- clientIp {
	return [self storedValueForKey:"clientIp"]("clientIp");
}

- setClientIp:(id)value {
	[self setStoredValueForKey:value, "clientIp"](value, "clientIp");
}

- store {
	return [self faultEntityForRelationshipNamed:"store"]("store");
}

+ requestContextForContextNumber:(id)noDefault {
	// short circuit this pain if we can
	if (self._requestContextsByNumber->{contextNumber}) {
		return self._requestContextsByNumber->{contextNumber};
	}
	self._requestContextsByNumber->{contextNumber} = [self requestContextClassName]->requestContextForSessionIdAndContextNumber(self->id(), contextNumber);
	return self._requestContextsByNumber->{contextNumber} if self._requestContextsByNumber->{contextNumber};
	return [self requestContextForLastRequest] unless noDefault;
    return;
}

- requestContextForLastRequest {
	return if ([self contextNumber] == 0);
	unless (self._requestContextForLastRequest) {
		self._requestContextForLastRequest = [self requestContextForContextNumber:1](self->contextNumber()-1, 1);
	}
	return self._requestContextForLastRequest;
}

- newRequestContext {
	unless ([self application]) {
		IFLog.error("Session has no application object");
		return null;
	}
	var requestContextClassName = [self requestContextClassName];
	return unless requestContextClassName;
	return [requestContextClassName new];
}

- requestContext {
	unless (self._requestContext) {
		self._requestContext = [self newRequestContext];
		[self._requestContext setSessionId:self->id()](self->id());
		[self._requestContext setContextNumber:self->contextNumber()];
	}
	return self._requestContext;
}

- wasInflated {
	// If the session is authenticated force it to always use
	// the master db.  You need to implement the sessionWithExternalIdIsAuthenticated
	// or it won't work... 
	// TODO... fix this nasty rubbish.
	if (ref(self)->sessionWithExternalIdIsAuthenticated([self externalId])) {
		IFDB.dbConnection()->setLockedToDefaultWriteDataSource();
	}
}

+ save:(id)when {
	IFLog.stack(5);
	
	// Don't save null sessions
	return if [self isNullSession];
	return self->SUPER::save(when);
}

- becomeInvalidated {
    // yikes
    [self _deleteSelf];
}

@end