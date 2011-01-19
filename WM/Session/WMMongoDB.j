@import <WM/WMSession.j>

var MAX_REQUEST_CONTEXTS = 6;


@implementation WMSessionMongoDB : WMSession
{
    id _id @accessors(property=id);
    id _lastActiveDate @accessors(property=lastActiveDate);
    id _clientIp @accessors(property=clientIp);
    id _contextNumber  @accessors(property=contextNumber);
    id _requestContextOffset @accessors(property=requestContextOffset);
    id _requestContexts @accessors(property=requestContexts);
}

//------------------------------------------------------
// Implements the Stash-based persistence of sessions.
// TODO rewrite the whole session-handling nonsense
// from the ground up.  For now this will have to
// suffice
//------------------------------------------------------


//--------------- Class Methods --------------------

+ (id) sessionWithExternalId:(id)id {
	var id = [WMUtility idFromExternalId:id];
    if (!id) { return nil }
	return [self instanceWithId:id];
}

+ (id) sessionWithExternalId:(id)id andContextNumber:(id)contextNumber {
	return [self sessionWithExternalId:id];
}

+ (id) sessionWithId:(id)id {
	return [self instanceWithId:id];
}

+ (id) sessionWithId:(id)id andContextNumber:(id)contextNumberj {
	return [self sessionWithId:id];
}

+ (id) externalIdRegularExpression {
	[WMLog error:"externalIdRegularExpression not overridden in Session subclass"];
}

+ (id) sessionWithExternalIdIsAuthenticated:(id)externalId {
	[WMLog error:"sessionWithExternalIdIsAuthenticated not overridden in Session subclass"];
}

// override this so that we don't need to change
// too many implementation details of the
// session subclass
+ (id) instanceWithId:(id)id {
    return [self stashedValueForKey:id];
}

// Note that the application-specified RequestContext class is ignored here.
// Rightly so; it should not be specified at that level, IMHO.
+ (id) requestContextClassName {
  return "WMSessionMongoDBRequestContext";
}


//----------------- Instance methods ------------------

- (id) init {
    [super init];
    _requestContexts = [];
}

// This is subtracted from the context number to fetch
// the request context from the array.  It allows us to
// only keep track of the last n requestContexts rather
// than store all of them.

//------------------ Core Methods --------------------

+ (id) requestContextForContextNumber:(id)contextNumber {
    for (var i=0; i<[_requestContexts count]; i++) {
        var rc = [_requestContexts objectAtIndex:i];
        if (![rc contextNumber] == contextNumber) { continue }
        return rc;
    }
    //IF::Log::error("RC context numbers don't match, possibly expired: $contextNumber");
    [WMLog error:"RC context numbers don't match, possible expired: " + contextNumber];
    return nil;
}

- (id) requestContextForLastRequest {
    if ([self contextNumber] == 0) { return nil }
	return [self requestContextForContextNumber:([self contextNumber] - 1)];
}

- (id) newRequestContext {
	if (![self application]) {
		[WMLog error:"Session has no application object"];
		return nil;
	}
	var requestContextClassName = [[self class] requestContextClassName];
    if (!requestContextClassName) { return nil }
    var c = objj_getClass(requestContextClassName);
	return [c new];
}

- (id) requestContext {
	if (!_requestContext) {
	    var nr = [self newRequestContext];
		_requestContext = nr;
    	[_requestContexts addObject:nr];
    	if ([_requestContexts count] > MAX_REQUEST_CONTEXTS) {
    	    [_requestContexts removeObjectAtIndex:0];
    	    _requestContextOffset++;
    	}
		[_requestContext setContextNumber:[self contextNumber]];
	}
	return _requestContext;
}

- (id) sessionValueForKey:(id)key {
    return _store[key];
}

- (id) setSessionValue:(id)value forKey:(id)key {
    _store[key] = value;
}

- (void) save:(id)when {
	// Don't save null sessions
    if ([self isNullSession]) { return }

	// Generate an ID if there isn't one:
    if (![self id]) {
	    //var sid = IFDB.nextNumberForSequence("SESSION_ID");
	    //[self setId:sid](sid);
        // TODO generate MongoID?
	}

    // unhook the application
    _applicationName = [[self application] name];
    _application = nil;

    // unhook the request context
    _requestContext = nil;

    // save self to DB
    //[self setStashedValueForKey:self, self->id()](self, self->id());
}

// This makes sure we remove the session from the stash.
- (void) becomeInvalidated {
    if ([self id]) {
        // clear DB for this id
        //[self setStashedValueForKey:null, self->id()](null, self->id());
    }
}

// we need to implement "is" since this doesn't descend from
// IF::Entity::Persistent
+ is:(id)other {
    if (!other) { return false }
    if (![other respondsToSelector:@SEL("id")]) { return false }
    return ([self id] == [other id]);
}

@end

//------------------------------------------------------------
// Here we are demoting the request context BS to a glorified
// dictionary; it need not be a first-class entity in the
// system and really only needs to be handled within a
// session.  It needs to respond to the same API as the
// entity version, but doesn't need to be persisted outside
// of the session
//------------------------------------------------------------

@implementation WMSessionMongoDBRequestContext : WMObject
{
    id _contextNumber @accessors(property=contextNumber);
    id _sessionId @accessors(property=sessionId);
    id _renderedComponents @accessors(property=renderedComponents);
    id _callingComponent @accessors(property=callingComponent);
}

// TODO add the methods here from the request context handling goo
@end