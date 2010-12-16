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

@import "WMObjectContext.j"
//@import "Utility.j"
@import "WMArray.j"
@import "WMResponse.j"
@import "Request/WMOfflineRequest.j"
@import "WMContext.j"
@import "WMTemplate.j"
@import "Bindings.js"

//@import "I18N.j"

var UTIL = require("util");
var PRINTF = require("printf");

// It would be way better if this data resided on the classes themselves
// rather than here, but perl doesn't have inheritable class data... ugh.
var DIRECT_ACTION_DISPATCH_TABLE = {};

// These are returned by "CONTENT" and "ATTRIBUTES" bindings
// and are handled by the including component
var COMPONENT_CONTENT_MARKER = '%_COMPONENT_CONTENT_%';
var TAG_ATTRIBUTE_MARKER     = '%_TAG_ATTRIBUTES_%';
var REGION_TAG_MARKER         = '<REGION NAME="%s">';
var COMPONENT_CONTENT_MARKER_RE = new RegExp(COMPONENT_CONTENT_MARKER);
var TAG_ATTRIBUTE_MARKER_RE     = new RegExp(TAG_ATTRIBUTE_MARKER, "g");
var REGION_TAG_MARKER_RE        = new RegExp(REGION_TAG_MARKER);

// WARNING: This MUST be maintained or the bindings
// will not get correctly resolved.  If you add another
// system binding type, you need to add it in here too.
var SYSTEM_BINDING_TYPES = {
    LOCALIZED_STRING: 1,
    STRING: 1,
    BOOLEAN: 1,
    DATE: 1,
    COMPONENT: 1,
    CONTENT: 1,
    PREFIX: 1,
    ASSOCIATION: 1,
    LOOP: 1,
    CONSUMER: 1,
    NUMBER: 1,
    ATTRIBUTES: 1,
    REGION: 1,
    SUBCOMPONENT_REGION: 1,
};

var TEMPLATE_IS_CACHED = {};
var BINDING_CACHE = {};


var BINDING_DISPATCH_TABLE = {
    // LOCALIZED_STRING: function(self, binding, context) {
    //     var key = binding['__private']['ATTRIBUTES'][binding['key']];
    //     return "" unless key;
    //     return
    //         _s( "", # why is this needed?  jesus.
    //             key,
    //             [context language],
    //             [context application]->name(),
    //         );
    // },
    STRING: function(self, binding, context) {
        //[WMLog debug:"Evaluating " + binding + " in " + self];
        var _value = [WMUtility evaluateExpression:binding['value'] inComponent:self context:context];
        if (binding['maxLength']) {
            var ml = binding['maxLength'];
            var maxLength = parseInt(ml) || [WMUtility evaluateExpression:ml inComponent:self context:context];
            if (maxLength && length(_value) > maxLength) {
                _value = _value.substring(0, (maxLength - 3)) + "...";
            }
        }
        if (binding['escapeHTML']) {
            _value = [WMUtility escapeHtml:_value];
        }
        if (binding['outgoingTextToHTML'] == "YES") {
            _value = [WMUtility formattedHtmlFromText:_value];
        }
        if (binding['filter']) {
            var filterName = binding['filter'];
            // TODO: this assumes a filter will be an instance method of this component,
            // which is a bit bogus; there should be general filters that can be
            // used anywhere.
            var filterExpression = "objj_msgSend(self, filterName + ':', _value)";
            var _value;
            try {
                _value = eval(filterExpression);
            } catch(e) {
                [WMLog error:"Failed to filter " + binding['_NAME'] + " because " + e];
                _value = "";
            }
        }
        return _value;
    },

    NUMBER: function(self, binding, context) {
        var format = [WMUtility evaluateExpression:binding['format'] inComponent:self context:context];
        var _value;
        try {
            _value = PRINTF.sprintf(format, [WMUtility evaluateExpression:binding['value'] inComponent:self context:context]);
        } catch (e) {
            [WMLog warning:"eval error: " + e + " while trying to evaluate " + binding['_NAME'] + " (" + binding['value'] + ")"];
        }
        return _value || 0;
    },
    DATE: function(self, binding, context) {
        var _value;
        try {
            _value = [WMUtility dateStringForUnixTime: [WMUtility evaluateExpression:binding['value'] inComponent:self context:context]];
        } catch (e) {
            [WMLog warning:"eval error: " + e + " while trying to evaluate " + binding['_NAME'] + " (" + binding['value'] + ")"];
        }
        return _value;
    },
    LOOP: function(self, binding, context) {
        var _value;
        try {
            _value = [WMUtility evaluateExpression:binding['list'] inComponent:self context:context];
        } catch (e) {
            [WMLog warning:"eval error: " + e + " while trying to evaluate " + binding['_NAME'] + " (" + binding['value'] + ")"];
            return [];
        }
        if (![WMArray isArray:_value]) {
            [WMLog warning:"Coercing scalar to LOOP " + _value];
            if (_value != null) {
                _value = [_value];
            } else {
                _value = [];
            }
        }
        return _value;
    },
    BOOLEAN: function(self, binding, context) {
        var _value;
        try {
            _value = [WMUtility evaluateExpression:binding['value'] inComponent:self context:context]? 1:0;
            if (binding['negate']) {
                _value = !_value;
            }
        } catch (e) {
            [WMLog warning:"eval error: " + e + " while trying to evaluate " + binding['_NAME'] + " (" + binding['value'] + ")"];
        }
        return _value;
    },
    CONTENT: function(self, binding, context) {
        return COMPONENT_CONTENT_MARKER;
    },
    ATTRIBUTES: function(self, binding, context) {
        return TAG_ATTRIBUTE_MARKER;
    },
    REGION: function(self, binding, context) {
        // build start and end tags for the region, and return them with a component content
        // indicator in the middle:
        var startTag = PRINTF.sprintf(REGION_TAG_MARKER, binding['name']);
        var endTag   = "</REGION>";
        [self setHasRegions:true];
        return startTag + COMPONENT_CONTENT_MARKER + endTag;
    },
    SUBCOMPONENT_REGION: function(self, binding, context) {
        var regionName = binding['name'];
        var bindingName = binding['binding'];
        var subcomponentBinding = [self bindingForKey:bindingName];
        if (subcomponentBinding) {
            if (!_regionCache[bindingName]) {
                //[WMLog debug:"Adding " + bindingName + " to region cache"];
                [self evaluateBinding:subcomponentBinding inContext:context];
                _regionCache[bindingName] = [self subcomponentForBindingNamed:bindingName];
            }
            return [_regionCache[bindingName] nextRegionForKey:regionName];
        } else {
            [WMLog error:"Couldn't load binding named " + bindingName + " when trying to render region " + regionName];
            return "<b>Region " + regionName + " not found for binding " + bindingName + "</b>";
        }
    },
    COMPONENT: function(self, binding, context) {
        [WMLog page:">>> " + binding['type'] + " : " + binding['_NAME'] + " : " + [self context]];
        [WMLog incrementPageStructureDepth];
        var _value = [self componentResponseForBinding:binding];
        [WMLog decrementPageStructureDepth];
        [WMLog page:"<<< " + binding['type'] + " : " + binding['_NAME'] + " : " + [self context]];
        if (!_value) {
            [WMLog warning:"error trying to evaluate binding " + binding['_NAME'] + " (" + binding['value'] + ")"];
        }
        return _value;
    },
};

@implementation WMComponent : WMObject
{
    id _context;
    id _bindings;
    id _didLoadBindings;
    id _subcomponents;
    WMComponent _parent;
    id _parentBindingName;
    id _synchronizesBindingsWithParent;
    id _synchronizesBindingsWithChildren;
    id _pageContextNumber;
    id _hasRegions;
    id _regions;
    id _regionCounters;
    id _regionCache;
    id _tagAttributes;
    id _directActionDispatchTable;
    id _overrides;
    id _templateName;
    id _template;
    id _renderState;
    //id _siteClassifier;
    id _componentName;
    id _componentNameRelativeToSiteClassifier;

    // This allows us to group these into hierarchies/folders/etc.
    // and still allow template/binding resolution to work.
    // It defaults to nothing, but you can add in a path
    // and template/binding resolution will use it.
    id _hierarchy;
}

+ (id) newWithBinding:(id)binding {
    var c = [super alloc];
    return [c initWithBinding:binding];
}

- (id) init {
    [super init];
    _context = nil;
    _bindings = nil;
    _didLoadBindings = false;
    _subcomponents = {};
    _parentBindingName = nil;
    _synchronizesBindingsWithParent = true;
    _synchronizesBindingsWithChildren = true;
    _pageContextNumber = 1;
    _hasRegions = false;
    _regions = {};
    _regionCounters = {};
    _regionCache = {};
    _tagAttributes = {};
    _directActionDispatchTable = nil;
    _overrides = {};
    _templateName = nil;
    _template = nil;
    _componentName = nil;
    _componentNameRelativeToSiteClassifier = nil;
    _hierarchy = "";
    //[WMLog debug:"Initialising " + self + ", _subcomponents = " + _subcomponents];
    return self;
}

- (id) initWithBinding:(id)binding {
    [self init];
    _pageContextNumber = binding['_defaultPageContextNumber'];
    return self;
}

// the template name for this component.
// You could override this, conceivably.
- (id) templateName {
    if (!_templateName) {
        _templateName = [WMComponent __templateNameFromComponentName:[self componentNameRelativeToSiteClassifier]];
    }
    return _templateName;
}

// You can override this to map a template name to another
// template at render time.
- (id) mappedTemplateNameFromTemplateName:(id)templateName inContext:(id)context {
    return templateName;
}

- (void) loadBindings {
    var componentName = [self componentNameRelativeToSiteClassifier];

    // FIXME: I've removed the site-classifier resolution of bindings
    // for now; until we can come up with a namespace scheme, or something
    // similar, we'll just do it via component inheritance.
    //_bindings = [[self _siteClassifier] bindingsForPath:componentName inContext:[self context]];
    var _bindings = [self _defaultBindings];
    if ([[self class] respondsToSelector:@SEL("Bindings")]) {
        _bindings = UTIL.update(_bindings, [[self class] Bindings]);
    } else if ([self respondsToSelector:@SEL("Bindings")]) {
        _bindings = UTIL.update(_bindings, [self Bindings]);
    }
    if (![WMLog assert:_bindings message:"Loaded bindings for componentName"]) {
        return;
    }

    _didLoadBindings = true;

    // we've loaded the bindings hash, so now we number the component
    // bindings in alpha order to generate the page context numbers

    var c = 0;
    var sortedKeys = UTIL.sort(UTIL.keys(_bindings));
    for (var i=0; i < sortedKeys.length; i++) {
        var bindingKey = sortedKeys[i];
        if (bindingKey == "inheritsFrom") { continue }
        var binding = [self bindingForKey:bindingKey];
        if (!binding) { continue }
        if (!binding['type']) { continue }
        binding['_NAME'] = bindingKey;    // This is so that the binding can identify itself
        if ([self bindingIsComponent:binding]) {
            // number the binding, but do not inflate
            // the component; it's an extremely expensive
            // operation that we don't need to do yet.

            _bindings[bindingKey]['_index'] = c;
            _bindings[bindingKey]['_defaultPageContextNumber'] = [self pageContextNumber] + "_" + c;

            // if the binding has an "overrides" property, it will be used
            // to replace any subcomponents in the tree matching the name
            // set in this property.
            // eg.  overrides: "RIGHT_NAVIGATION_0",

            if (binding['overrides']) {
                _overrides[binding['overrides']] = binding;
            }
            c++;
        }
    }
    // remove the 'inheritsFrom' designation from the bindings
    // dictionary if it's there so we don't need to check for it
    // in the future
    delete _bindings['inheritsFrom'];
}

- (id) Bindings {
    return {};
}

// Man, a state machine.  Weird.  This needs to be unwound into
// a real state machine as it's essentially a huge switch statement
// right now

- (id) appendToResponse:(id)response inContext:(id)context {
    // The component's ivar
    // _context gets set the context that was passed in so
    // that it's available during rendering for other methods.
    if (context) {
        _context = context;
    }

    // add any page resources that the component is requesting:
    var renderState = [response renderState];
    [self _setRenderState:renderState];
    [renderState addPageResources:[self requiredPageResources]];

    if (context && [context session]) {
        var requestContext = [[context session] requestContext];
        if (![requestContext callingComponent]) {
            [requestContext setCallingComponent:[self componentName]];
        }
    }

    var template = [self template];

    if (!template) {
        // what to do here?
        _context = nil;
        [self _setRenderState:nil];
        throw [CPException raise:"CPException" reason:"Couldn't find template for response"];
    }

    var pregeneratedContent = {};
    var flowControl = {};
    var loops = {};
    var currentLoopDepth = 0;
    var regionCache = {};
    var loopContextVariables = {
        __ODD__: 1,
        __EVEN__: 2,
        __FIRST__: 3,
        __LAST__: 4,
    };

    var legacyLoops = [];
    for (var i=0; i<[template contentElementCount];) {
        var contentElement = [template contentElementAtIndex:i];
        if (pregeneratedContent[i]) {
            [response appendContentString:pregeneratedContent[i]];
            delete pregeneratedContent[i];
        }
        if (flowControl[i]) {
            if (flowControl[i]['command'] == "SKIP") {
                i = flowControl[i]['index'];
            }
            delete flowControl[i];
            continue;
        }

        // FIXME: try to be a bit smarter about detecting this
        // eg. handle these content element nodes with polymorphism!
        if (contentElement && typeof contentElement != "string") {
            var _value;
            if (contentElement['BINDING_TYPE'] == "BINDING") {
                if (contentElement['IS_END_TAG']) {
                    i += 1;
                    continue;
                }

                var binding = [self bindingForKey:contentElement['BINDING_NAME']] ||
                               contentElement['BINDING'];
                if (!binding) {
                    i += 1;
                    // TODO only enable this in development:
                    //  [self _appendErrorStringToResponse(
                    //    "Binding $contentElement->{BINDING_NAME} not found", $response);
                    continue;
                }

                // HACK WARNING: TODO Fix this!
                // This grabs any attributes that were specified in the
                // template, and sets them on the binding that's being
                // used to generate the subcomponent.  That way, the
                // subcomponent can grab attributes directly
                // and access them if need be
                //
                binding['__private'] = binding['__private'] || {};
                binding['__private']['ATTRIBUTES'] = contentElement['ATTRIBUTE_HASH'] || {};
                _value = [self evaluateBinding:binding inContext:context];
                delete binding['__private']['ATTRIBUTES'];
                // add it to the list of components to flush on an
                // iteration, if it's inside a loop
                //
                if (binding['type'] == "SUBCOMPONENT_REGION") {
                    if (currentLoopDepth > 0) {
                        var sortedLoops = UTIL.values(loops).sort(function (a, b) { b['depth'] - a['depth'] });
                        var highestLoop = sortedLoops[0];
                        highestLoop['flushOnExit'][binding['binding']] = true;
                        //WM::Log::debug("Adding $binding->{binding} to the flush queue");
                    }
                }
                if ([self bindingIsComponent:binding] || binding['type'] == "REGION" || binding['type'] == "SUBCOMPONENT_REGION") {
                    if (contentElement['END_TAG_INDEX']) {
                        if (_value.match(COMPONENT_CONTENT_MARKER_RE)) {
                            var bits = _p_2_split(COMPONENT_CONTENT_MARKER_RE, _value);
                            var openTagReplacement = bits[0];
                            var closeTagReplacement = bits[1];
                            _value = openTagReplacement;
                            pregeneratedContent[contentElement['END_TAG_INDEX']] = closeTagReplacement;
                            [WMLog debug:"value is " + _value + " end tag is " + closeTagReplacement];
                        } else {
                            [response appendContentString:_value];
                            i = contentElement['END_TAG_INDEX'] + 1;
                            continue;
                        }
                    }

                    if (binding['type'] != "REGION") {
                        // this is bent because it needs to be evaluated one level lower in
                        // the component tree.  here, the including component evaluates the
                        // attributes for the included component.
                        //
                        var tagAttributes = contentElement['ATTRIBUTES'] || "";
                        // process it using craig's cleverness, but first set the parent up
                        // so the hierarchy is preserved - this is a temporary hack
                        //
                        var c = [self subcomponentForBindingNamed:binding['_NAME']];
                        if ([WMLog assert:c message:"Subcomponent for binding " + binding['_NAME'] + " exists"]) {
                            [c setParent:self];
                            tagAttributes = [self _evaluateKeyPathsInTagAttributes:tagAttributes onComponent:c];
                            [c setParent:nil];
                        }
                        //WM::Log::debug("Tag attribute string is $tagAttributes for binding $binding->{NAME}");

                        //WMLog debug:binding['_NAME'] + " " + value];
                        _value = _value.replace(TAG_ATTRIBUTE_MARKER_RE, tagAttributes);
                    }
                }
                //} // __LEGACY__
                [response appendContentString:_value];
                i++;
                continue;
            } else if (contentElement['BINDING_TYPE'] == "BINDING_IF" ||
                     contentElement['BINDING_TYPE'] == "BINDING_UNLESS") {
                if (contentElement['IS_END_TAG']) {
                    if (!contentElement['START_TAG_INDEX']) {
                        var error = [WMTemplate errorForKey:"NO_MATCHING_START_TAG_FOUND", contentElement['BINDING_NAME'], i];
                        [WMLog error:error];
                        [self _appendErrorString:error toResponse:response];
                    }
                    i += 1;
                    continue;
                } else {
                    if (!contentElement['END_TAG_INDEX'] && !contentElement['ELSE_TAG_INDEX']) {
                        var error = [WMTemplate errorForKey:"NO_MATCHING_END_TAG_FOUND", contentElement['BINDING_NAME'], i];
                        [WMLog error:error];
                        [self _appendErrorString:error toResponse:response];
                        i += 1;
                        continue;
                    }
                }
                var condition;
                var binding = [self bindingForKey:contentElement['BINDING_NAME']];
                if (!binding) {
                    i++;
                    continue;
                }
                condition = [self evaluateBinding:binding inContext:context];

                if (condition && condition.isa && [condition isKindOfClass:"CPArray"]) {
                        condition = condition.length;
                }
                if (contentElement['BINDING_TYPE'] == "BINDING_UNLESS") {
                    condition = !condition;
                }
                // decide what to include
                if (condition) {
                    i++;
                    if (contentElement['ELSE_TAG_INDEX']) {
                        flowControl[contentElement['ELSE_TAG_INDEX']] = {
                            command: "SKIP",
                            index: contentElement['END_TAG_INDEX'],
                        };
                    }
                    continue;
                } else {
                    if (contentElement['ELSE_TAG_INDEX']) {
                        i = contentElement['ELSE_TAG_INDEX'] + 1;
                    } else {
                        i = contentElement['END_TAG_INDEX'];
                    }
                    continue;
                }
            } else if (contentElement['BINDING_TYPE'] == "BINDING_LOOP") {
                if (contentElement['IS_END_TAG']) {
                    if (!contentElement['START_TAG_INDEX']) {
                        var error = [WMTemplate errorForKey:"NO_MATCHING_START_TAG_FOUND", contentElement['BINDING_NAME'], i];
                        [self _appendErrorString:error toResponse:response];
                        i += 1;
                        [renderState decreaseLoopContextDepth];
                    } else {
                        i = contentElement['START_TAG_INDEX'];
                        [renderState incrementLoopContextNumber];
                    }
                    continue;
                } else {
                    if (!contentElement['END_TAG_INDEX']) {
                        var error = [WMTemplate errorForKey:"NO_MATCHING_END_TAG_FOUND", contentElement['BINDING_NAME'], i];
                        [self _appendErrorString:error toResponse:response];
                        i += 1;
                        continue;
                    }
                }
                var loopName;
                var binding = [self bindingForKey:contentElement['BINDING_NAME']];
                if (!binding) {
                    if (contentElement['END_TAG_INDEX']) {
                        i = contentElement['END_TAG_INDEX'] + 1;
                    } else {
                        i += 1;
                    }
                    continue;
                }
                loopName = contentElement['BINDING_NAME'];
                if (!loops[loopName]) {
                    loops[loopName] = {
                        list: [self evaluateBinding:binding inContext:context],
                        index: 0,
                        itemKey: binding['item'] || binding['ITEM'],
                        indexKey: binding['index'] || binding['INDEX'],
                        depth: currentLoopDepth,
                        isLegacy: 0,
                        flushOnExit: {},
                    };
                    currentLoopDepth++;
                    [renderState increaseLoopContextDepth];
                }

                // decide if we want to skip
                var listSize = 0;
                if (loops[loopName]['list']) {
                    listSize = loops[loopName]['list'].length;
                }
                var loopIndex = loops[loopName]['index'];
                if (loopIndex >= listSize || listSize == 0 || !loops[loopName]['list']) {
                    if (loops[loopName]['isLegacy']) {
                        legacyLoops.pop();
                    }

                    // Flush any queued components
                    for (var scn in loops[loopName]['flushOnExit']) {
                        var sc = [self subcomponentForBindingNamed:scn];
                        if (!sc) { continue }
                        delete _regionCache[scn];
                        [sc flushRegions];
                    }

                    delete loops[loopName];
                    currentLoopDepth--;
                    [renderState decreaseLoopContextDepth];
                    i = contentElement['END_TAG_INDEX'] + 1;
                    continue;
                }

                // we're not skipping so
                var itemKey = loops[loopName]['itemKey'];
                var indexKey = loops[loopName]['indexKey'];
                if (itemKey) {
                    [self setValue:nil forKey:itemKey]; // clear it out?
                    [self setValue:loops[loopName]['list'][loopIndex] forKey:itemKey];
                    //WM::Log::dump($loops->{$loopName}->{list}->[$loopIndex]);
                }
                if (indexKey) {
                    [self setValue:loopIndex forKey:indexKey];
                }
                loops[loopName]['index'] = loops[loopName]['index'] + 1;
                i++;
                continue;
            } else if (contentElement['BINDING_TYPE'] == "KEY_PATH") {
                [response appendContentString:[self valueForKey:contentElement['KEY_PATH']]];
            }
        } else {
            [response appendContentString:contentElement];
        }
        i++;
    }

    if (context && [context session]) {
        [[[context session] requestContext] addRenderedComponent:self];
    }

    if ([self hasRegions]) {
        [self parseRegionsFromResponse:response];
    }

    // clean up the bindings cache and fix up the header
    if ([self isRootComponent]) {
        BINDING_CACHE = {};
        [self addPageResourcesToResponse:response inContext:context];
    }

    // Trying to allow components to reset their values
    [self resetValues];
    [self _setRenderState:nil];
    _context = nil;
    return;
}

- resetValues {
    // override this to reset your component between rendered instances.
}

// TODO - this won't work correctly for asynchronous components
// that renumber themselves to start with a different page
// context number -kd
//
- isRootComponent {
    return ([self pageContextNumber] == '1');
}

- rootComponent {
    var currentComponent = self;
    while (1) {
        if ([currentComponent isRootComponent]) {
            return currentComponent;
        }
        currentComponent = [currentComponent parent];
        if (!currentComponent) {
            return self;
        }
    }
    return self;
}

- (Boolean) isFirstTimeRendered {
    var componentName = [self componentName];
    if ([[[[self context] session] requestContext] didRenderComponentWithName:componentName]) { return false }
    return true;
}

// generate a *text* name for the component that's unique
- (id) uniqueId {
    return "c" + [self renderContextNumber];
}

- (id) renderContextNumber {
    var pcn = [self pageContextNumber];
    renderState = [self _renderState];
    if (renderState && [renderState loopContextDepth] > 0) {
        pcn = pcn + "L" + [renderState loopContextNumber];
    }
    return pcn;
}

// hmpf, this is necessary if we want the page to reinflate dynamically generated
// form components correctly. -kd
//
- (id) queryKeyNameForPageAndLoopContexts {
    return [self renderContextNumber];
}


- (id) bindings {
    if (!_didLoadBindings) {
        [self loadBindings];
    }
    return _bindings;
}

- (id) bindingForKey:(id)key {
    // automatically try the uppercase binding name if we can't find the one passed in.
    // It's a legacy thing; all the old binding names used to be in caps.
    //
    if (![WMLog assert:key message:"bindingForKey: called with no key name"]) { return nil }
    var bs = [self bindings];
    var b = bs[key] || bs[key.toUpperCase()];
    // Allow overrides
    var fullPathToBinding = [self nestedBindingPath] + "__" + key;
    var ob = [self overrideForPath:fullPathToBinding];
    if (ob && b) {
        [WMLog debug:"OVERRIDE found for " + key];
        ob['_index'] = b['_index'];
        ob['_defaultPageContextNumber'] = b['_defaultPageContextNumber'];
        ob['_NAME'] = b['_NAME'];
        [WMLog dump:b];
        b = ob; // then switch it into place for this pass.
        [WMLog dump:b];
    }

    // cheesy error message
    if (!b) {
        if ([self allowsDirectAccess]) {
            return {
                type: "STRING",
                //value: key + "(context)",
                value: key,
            };
        }
        //WM::Log::debug("Couldn't find binding with name $key");
        var error = [WMTemplate errorForKey:"BINDING_NOT_FOUND", key];
        return {
            type: "STRING",
            value: "\'" + error + "\'",
        }
    }
    return b;
}

- (id) evaluateExpression:(id)expression {
    var context = [self context];
    return eval(expression);
}


- (id) evaluateBinding:(id)binding inContext:(id)context {
    if (!binding) return;
    var bindingType = [self bindingIsComponent:binding] ? "COMPONENT" : binding['type'];
    var dispatch = BINDING_DISPATCH_TABLE[bindingType];
    //[WMLog debug:"evaluateBinding: " + bindingType + " binding is " + binding.toSource()];
    [WMLog debug:"  ----------> start dispatching (" + binding['_NAME']+ ")"];
    var rv = dispatch(self, binding, context);
    [WMLog debug:"  <---------- end dispatching (" + binding['_NAME']+ ")"];
    return rv;
}

- (id) componentResponseForBindingNamed:(id)bindingKey {
    //[WMLog debug:"componentResponseForBindingNamed:" + bindingKey];
    var binding = [self bindingForKey:bindingKey];
    return [self componentResponseForBinding:binding];
}

// TODO remove most of this bloat... it's repeated and unnecessary.
- (id) componentResponseForBinding:(id)binding {
    var context = [self context];
    var renderState = [self _renderState];
    var bindingKey = binding['_NAME'];
    var bindingClass = binding['value'] || binding['type'];
    var componentName = [WMUtility evaluateExpression:bindingClass inComponent:self context:context] || bindingClass;
    var templateName = [WMComponent __templateNameFromComponentName:componentName];
    var response = [WMResponse new];
    [response setRenderState:renderState];
    var component = [self subcomponentForBindingNamed:bindingKey];
    /*
    if (component && [component hasCompiledResponse]) {
        // ?
    } else {
        template = [[self _siteClassifier] bestTemplateForPath:templateName andContext:context];
    }
    [response setTemplate:template];
    */

    if (!component) {
        component = [self pageWithName:componentName];

        if (!component) {
            [WMLog error:"no component - " + bindingKey];
            return nil;
        }
        [component setParentBindingName:bindingKey];
        [renderState incrementPageContextNumber];
        [component setPageContextNumberRoot:[renderState pageContextNumber]];

        // TODO probably blow this away; obviated by SwitchComponent
        // if it's a late-binding component name, it's not in $[self {_subcomponents}
        // so stash the component object that we just created in there.
        //
    }
    if (![component context]) {
        [component setContext:context];
    }
    var template = [component template];
    [component _setRenderState:renderState];
    [component setTagAttributes:binding['__private']['ATTRIBUTES']];
    [component setParent:self];
    [component pullValuesFromParent];
    [component appendToResponse:response inContext:context];
    [component setParent:nil];

    // reset the tag attributes
    [component setTagAttributes:{}];

    // TODO would be cooler to return un-rendered; perhaps look
    // into returning a closure that would render?
    return [response content];
}

- (WMComponent) pageWithName:(id)componentName andAttributes:(id)attributes {
    var component = [self pageWithName:componentName];
    if (!component) { return nil }
    for (var key in attributes) {
        var _value = [WMUtility evaluateExpression:attributes[key] inComponent:self context:[self context]]
        [component setValue:_value forKey:key];
    }
    return component;
}

- (WMComponent) pageInSite:(id)siteClassifierPath withName:(id)componentName {
    if (siteClassifierPath == [[self siteClassifier] componentClassName]) {
        return [self pageWithName:componentName];
    }
    var siteClassifierClassName = [[self application] siteClassifierClassName];
    var scClass = objj_getClass(siteClassifierClassName);
    var siteClassifier = [scClass siteClassifierWithComponentClassName:siteClassifierPath];
    [[self context] setSiteClassifier:siteClassifier];
    return [self pageWithName:componentName];
}

- (WMComponent) pageWithName:(id)componentName {
    var c = [[self _siteClassifier] componentForName:componentName andContext:[self context]];
    [c setContext:[self context]];
    return c;
}

// theft! theft!
// NOTE: this should be takeValuesFromRequest:(id)request inContext:(id)context
// but for now, request and context are wrapped up into one; the reason for this
// is because it originally mapped nicely to the Apache request object, and I
// didn't have time to make the abstraction between Request and Context.
// It's on my list to fix.
- (void) takeValuesFromRequest:(id)context {
    if ([self isRootComponent]) {
        if (![context session]) { return }
        if (![context lastRequestWasSpecified]) { return }

        var lastRequestContext = [[context session] requestContextForContextNumber:[context contextNumber]];

        // Only a Kiwi will get this joke.
        if (![WMLog assert:lastRequestContext message:"No last request.  Well, maybe a pixie caramel. " + [context contextNumber]]) { return }

        if ([lastRequestContext didRenderComponentWithName:[self componentName]]) {
            var callingComponentPageContextNumber = [lastRequestContext pageContextNumberForCallingComponent:[self componentName] inContext:context];
            [context setCallingComponentPageContextNumber:callingComponentPageContextNumber];
        } else {
            //WM::Log::dump($lastRequestContext);
            [WMLog debug:"Did not render " + [self componentName] + " in past request"];
            return;
        }
    }

    // forward "takeValues" to subcomponents after trying to set
    // their bindings. don't try to optimise this lastRequestContext call
    // out because it needs to be here and also above.  think about it and you'll see why.
    //
    var lastRequestContext = [[context session] requestContextForContextNumber:[context contextNumber]];
    [WMLog assert:lastRequestContext message:"Last request context refetched correctly for context number " + [context contextNumber]];
    var callingComponentPageContextNumber = [context callingComponentPageContextNumber];
    for (var bindingKey in [self bindings]) {
        if (typeof _bindings[bindingKey][_index] == "undefined") { continue } // if it has an index it's a component
        var subcomponent = [self subcomponentForBindingNamed:bindingKey];
        if (![WMLog assert:subcomponent message:"Subcomponent exists for " + bindingKey]) { continue }
        var oldPageContextNumber = [subcomponent pageContextNumber];
        if (callingComponentPageContextNumber) {
            // set pageContextNumber relative to the calling component
            var newPageContextNumber = oldPageContextNumber;
            // FIXME : potential bug here with matching numbers starting with a 1, like 10
            newPageContextNumber = newPageContextNumber.replace(/^1/, callingComponentPageContextNumber);
            [subcomponent setPageContextNumber:newPageContextNumber];
        }
        if (!(lastRequestContext && [lastRequestContext didRenderComponentWithPageContextNumber:[subcomponent renderContextNumber]])) {
            //WM::Log::debug("Skipping takeValues for component ".$subcomponent->componentName()." / ".$subcomponent->renderContextNumber());
            continue;
        }
        // FIXME this is not necessary in objj since the garbage collector works correctly
        // and will not be fooled by circular refs
        [subcomponent setParent:self];
        // kinda nasty but during binding sync, the context needs to be accessible to
        // the subcomponent *before* its tvfr is called
        //
        [subcomponent setContext:context];
        [subcomponent pullValuesFromParent];
        [subcomponent takeValuesFromRequest:context];
        [subcomponent pushValuesToParent];
        [subcomponent setParent:nil];
        if (callingComponentPageContextNumber) {
            [subcomponent setPageContextNumber:oldPageContextNumber];
        }
        // This should reset the component into its initial state
        // so that if the same component is re-used (say, in a loop or dynamic form)
        // it doesn't have any stale values in it.
        //
        [subcomponent resetValues];
    }
}

- (void) pullValuesFromParent {
    if (![self parent] || ![[self parent] synchronizesBindingsWithChildren]
        || ![self synchronizesBindingsWithParent]) { return }
    [[self parent] pushValuesToComponent:self];
}

- (void) pushValuesToComponent:(id)component {
    var binding = [self bindingForKey:[component parentBindingName]];
    if (!binding) {
        //[WMLog debug:"parent binding name " + [component parentBindingName] + " returned no binding"];
        return;
    }
    [self pushValuesToComponent:component usingBindings:binding['bindings']];
}

- (void) pushValuesToComponent:(id)component usingBindings:(id)bindings {
    // set the bindings
    var bs = bindings || {};
    [WMLog debug:"Preparing to push bindings to child"];
    for (var key in bs) {
        var _value = [WMUtility evaluateExpression:bindings[key] inComponent:self context:[self context]];
        //[WMLog debug:"Pushing binding " + key + " with value " + _value];
        [component setValue:_value forKey:key];
    }
}

- (void) pushValuesToParent {
    if (![self parent] || ![[self parent] synchronizesBindingsWithChildren]
        || ![self synchronizesBindingsWithParent]) { return }
    [[self parent] pullValuesFromComponent:self];
}

- (void) pullValuesFromComponent:(id)component {
    var binding = [self bindingForKey:[component parentBindingName]];

    // set the bindings
    var bs = bindings['bindings'] || {};
    for (var key in bs) {
        // TODO get rid of this?
        if (![component shouldAllowOutboundValueForBindingNamed:key]) { continue }
        if (![WMUtility expressionIsKeyPath:bs[key]]) { continue }
        var _value = [component valueForKeyPath:key];
        //WM::Log::debug("Pull: ".$[self componentNameRelativeToSiteClassifier()."  ($binding->{bindings}->{$key})"
        //    ." <-- ".$component->componentNameRelativeToSiteClassifier()." ($key, $value)");
        //
        [self setValue:_value forKeyPath:bs[key]];
    }
}

// this lazily inflates component instances from bindings
// only when they're requested for the first time.
//
- (WMComponent) subcomponentForBindingNamed:(id)bindingName {
    //[WMLog debug:"subcomponentForBindingNamed: " + bindingName + " / " + _subcomponents];
    if (_subcomponents[bindingName]) {
        return _subcomponents[bindingName]
    }

    // Allow overrides
    var fullPathToBinding = [self nestedBindingPath] + "__" + bindingName;
    var ob = [self overrideForPath:fullPathToBinding];
    var b = [self bindingForKey:bindingName];
    if (ob && b) {
        // set the override to look the same as the binding to the system
        ob['_index'] = b['_index'];
        ob['_defaultPageContextNumber'] = b['_defaultPageContextNumber'];
        ob['_NAME'] = b['_NAME'];
        [WMLog dump:b];
        b = ob; // then switch it into place for this pass.
        [WMLog dump:b];
    }

    //WM::Log::debug("Instantiating binding $bindingName with index ".$b->{_index}." dpc ".$b->{_defaultPageContextNumber});

    // instantiate it
    //my $subcomponent = $[self context()->siteClassifier()->componentForBindingInContext($b, $[self context());
//
    var subcomponent = [[self _siteClassifier] componentForBinding:b inContext:[self context]];

    if ([WMLog assert:subcomponent message:"Inflated component for binding " + bindingName]) {
        // Tell the subcomponent which of its parent's bindings
        // created it...  this is used when the parent resolves
        // requests
        //
        [subcomponent setParentBindingName:bindingName];
        //WM::Log::debug("Context is ".$subcomponent->pageContextNumber()." id is ".$subcomponent->uniqueId());
        _subcomponents[bindingName] = subcomponent;
    }
    return _subcomponents[bindingName];
}

- (id) invokeDirectActionNamed:(id)directActionName inContext:(id)context {
    if (!directActionName) { return }

    // expose the context to action handlers
    _context = context;

    // only invoke a method if it's predefined
    var methodName;
    var targetPageContextNumber;
    var targetComponentDirectActionName;
    var defaultDirectAction = [[context application] configurationValueForKey:"DEFAULT_DIRECT_ACTION"];

    if (directActionName == defaultDirectAction) {
        methodName = defaultDirectAction + "Action:";
    } else {
        if (directActionName.match(/^[0-9\_]+\-[A-Za-z0-9_]+$/)) {
            var bits = directActionName.split("-");
            targetPageContextNumber = bits[0];
            targetComponentDirectActionName = bits[1];
            if (targetPageContextNumber == "1") {
                methodName = [self actionMethodForAction:targetComponentDirectActionName];
                //WM::Log::debug("Action method name is $methodName");
            }
            if (!methodName && targetComponentDirectActionName == defaultDirectAction) {
                methodName = defaultDirectAction + "Action:";
            }
        } else {
            methodName = [self actionMethodForAction:directActionName];
            if (!methodName) {
                [WMLog warning:"No action method for " + directActionName + " on " + [self componentName]];
            }
        }
    }

    [WMLog debug:[self pageContextNumber] + methodName + "/" + targetComponentDirectActionName + " / " + targetPageContextNumber];
    if (!methodName && !targetComponentDirectActionName) { return }

    // check for action, and invoke it if present
    if (targetPageContextNumber && targetPageContextNumber != "1") {
        // forward directAction to subcomponents:

        //foreach my $subcomponent (values %{$[self {_subcomponents}}) {
        var bs = [self bindings];
        for (var sk in bs) {
            if (typeof bs[sk]["_index"] == "undefined") { continue }
            var subcomponent = [self subcomponentForBindingNames:sk];
            [WMLog assert:subcomponent message:"Subcomponent for key sk exists"];
            [subcomponent setParent:self];
            var returnValue;
            if ([subcomponent pageContextNumber] == targetPageContextNumber) {
                returnValue = [subcomponent invokeDirectActionNamed:targetComponentDirectActionName inContext:context];
            } else {
                returnValue = [subcomponent invokeDirectActionNamed:directActionName inContext:context];
            }
            [subcomponent setParent:nil];

            if (returnValue) { return returnValue }
        }
    } else {
        if ([self respondsToSelector:@SEL(methodName)]) {
            // invoke method
            [WMLog debug:"Invoking method " + methodName + " on " + self];
            return objj_msgSend(self, methodName, context);
        } else {
            [WMLog warning:"Attempt to invoke method " + methodName + " on " + self + " failed"];
        }
        [WMLog debug:"No method for action " + directActionName + " found."];
    }
    return;
}

- invokeMethodWithArguments:(id)methodName, ... {
    if (![self respondsToSelector:@SEL(methodName)]) { return }
    //return [self methodName:_](_);
}

//--------------------------------------
// methods for handling regions
//--------------------------------------
//

- (Boolean) hasRegions {
    return _hasRegions;
}

- (void) setHasRegions:(Boolean)_value {
    _hasRegions = _value;
}

- (Boolean) hasRegionsForKey:(id)key {
    if (![self hasRegions]) { return false }
    if (typeof [self regions][key] != 'undefined') { return true }
    return false;
}

- (id) regions {
    return _regions;
}

- (id) regionsForKey:(id)key {
    //[WMLog debug:"Req for regionsForKey(" + key + ")"];
    if (![self hasRegionsForKey:key]) { return [] }
    return _regions[key];
}

- (id) regionsOfSubcomponentForKey:(id)key {
    var subcomponent = [self subcomponentForBindingNamed:subcomponentName];
    //[WMLog debug:"Req for subc " + subcomponentName + " for key " + key];
    var binding = [self bindingForKey:subcomponentName];
    if (![WMLog assert:subcomponent message:"Found subcomponent named " + subcomponentName]) { return }

    // TODO ungarble this... why does it re-fetch the binding and subcomponent
    if (!_regionCache[subcomponentName]) {
        var subcomponentBinding = [self bindingForKey:subcomponentName];
        //[WMLog debug:"Adding " + subcomponentName + " to region cache"];
        [self evaluateBinding:subcomponentBinding inContext:[self context]];
        _regionCache[subcomponentName] = [self subcomponentForBindingNamed:subcomponentName];
    }
    return [_regionCache[subcomponentName] regionsForKey:key];
}

- (void) setRegions:(id)regions forKey:(id)key {
    _regions[key] = regions;
}

- (id) nextRegionForKey:(id)key {
    var regionsForKey = [self regionsForKey:key];
    if (regionsForKey.length > _regionCounters[key]) {
        var _value = regionsForKey[_regionCounters[key]];
        _regionCounters[key] += 1;
        return _value;
    }
    return nil; // we return null if we've gone off the end + ..
}

- (void) flushRegions {
    //WM::Log::debug("Flushing regions for ".$[self componentName());
    _regions = {};
    _regionCounters = {};
    _regionCache = {};
}

- (void) parseRegionsFromResponse:(id)response {
    //[WMLog debug:"Regions found in component " + self];
    var content = [response content];
    var rre = new RegExp('<REGION NAME="([^"]*)">(.*?)<\/REGION>', 'gi');
    var match;
    while (match = content.match(rre)) {
        var all = match[0];
        var regionName = match[1];
        var region = match[2];
        var regions = [self regionsForKey:regionName];
        regions.push(region);
        [self setRegions:regions forKey:regionName];
        content = content.replace(/<REGION[^>]*>/, "<!-- region -->");
        content = content.replace(/<\/REGION[^>]*>/, "<!-- /region -->");
    }

    // strip regions and reset content
    [response setContent:content];
}

- (void) setParentBindingName:(id)_value {
    _parentBindingName = _value;
}

- (id) parentBindingName {
    return _parentBindingName;
}

// this returns the names of bindings in
// the nesting hierarchy.  eg. if a component
// whose binding name is EMAIL_ADDRESS is
// embedded inside another called BILLING_INFO_EDITOR
// the path returned will be
// BILLING_INFO_EDITOR__EMAIL_ADDRESS
//
- (id) nestedBindingPath {
    var bindings = [];
    var current = self;
    while (current && [current parentBindingName]) {
        // Issue: 1425 - Switch component's child has its parent binding
        // path set to the switch component's parent so this avoid a
        // duplicate path element in the nested binding path.
        //
        if (current.isa != "WMSwitchComponent") {
            bindings.unshift([current parentBindingName]);
        }
        current = [current parent];
    }
    return bindings.join("__");
}

- (id) overrideForPath:(id)path {
    for (var k in _overrides) {
        var re = new RegExp(k + '$');
        if (path.match(re)) {
            return _overrides[k];
        }
    }
    if ([self parent]) {
        return [[self parent] overrideForPath:path];
    }
    return nil;
}

- (id) parent {
    return _parent;
}

- (void) setParent:(id)_value {
    _parent = _value;
}

// Override this if there are bindings you do not wish synchronized:
- (Boolean) shouldAllowOutboundValueForBindingNamed:(id)bindingName {
    return true;
}

- (Boolean) synchronizesBindingsWithParent {
    return _synchronizesBindingsWithParent;
}

- (void) setSynchronizesBindingsWithParent:(Boolean)_sync{
    _synchronizesBindingsWithParent = _sync;
}

- (Boolean) synchronizesBindingsWithChildren {
    return _synchronizesBindingsWithChildren;
}

- (void) setSynchronizesBindingsWithChildren:(Boolean)_sync {
    _synchronizesBindingsWithChildren = _sync;
}

- (id) _loopIndices {
    return _loopIndices;
}

- (void) _setLoopIndices:(id)_v {
    _loopIndices = _v;
}

- (id) pageContextNumber {
    return _pageContextNumber;
}

- (void) setPageContextNumber:(id)_v {
    _pageContextNumber = _v;
}

- (void) setPageContextNumberRoot:(id)root {
    //WM::Log::debug("Setting ".$[self {_pageContextNumber}." to $root");
    _pageContextNumber = root;

    // renumber the subcomponents
    // TODO - can't we do this with the _index that's already in the binding?
    //
    var subcomponentCounter = 0;
    var sortedKeys = UTIL.sort(UTIL.keys([self bindings]));
    for (var i=0; i < sortedKeys.length; i++) {
        var bindingKey = sortedKeys[i];
        if (typeof _bindings[bindingKey][_index] == "undefined") { continue }
        var subcomponent = [self subcomponentForBindingNamed:bindingKey];
        if ([WMLog assert:subcomponent message:"Retrieved subcomponent " + bindingKey + " during renumbering"]) {
            [subcomponent setPageContextNumberRoot:[self pageContextNumber] + "_" + subcomponentCounter];
        }
        subcomponentCounter++;
    }
}

- (id) context {
    return _context;
}

- (void) setContext:(id)context {
    _context = context;
    var sortedKeys = UTIL.sort(UTIL.keys(_subcomponents));
    for (var i=0; i < sortedKeys.length; i++) {
        var bindingName = sortedKeys[i];
        var subcomponent = _subcomponents[bindingName];
        //[WMLog debug:subcomponent];
        //if (subcomponent.isa != "WMComponent") {
        //    [WMLog dump:_subcomponents];
        //}
        [subcomponent setContext:context];
    }
}

// this is used internally by methods trying to derive
// the current site classifier object; if it's not found,
// we return the default
//
- (id) _siteClassifier {
    //[WMLog debug:"_siteClassifier called"];
    if ([self context] && [[self context] siteClassifier]) {
        return [[self context] siteClassifier];
    }
    //[WMLog debug:"Getting default site classifier from application"];
    var sc = [[WMApplication defaultApplication] defaultSiteClassifier];
    //[WMLog debug:sc];
    return sc;
}

- (id) session {
    if (![self context]) { return nil }
    return [[self context] session];
}

- (WMObjectContext) objectContext {
    if (_defaultObjectContext) { return _defaultObjectContext }
    _defaultObjectContext = [WMObjectContext new];
    return _defaultObjectContext;
}

- (WMApplication) application {
    if ([self context]) { return [[self context] application] }
    return [WMApplication defaultApplication];
}

//
//- actionMethodForAction:(id)actionName {
//    var package = ref(self);
//    return self._directActionDispatchTable->{actionName}
//        || DIRECT_ACTION_DISPATCH_TABLE[package]->{actionName};
//}
//

- (id) performParentAction:(id)actionName inContext:(id)context {
    if (![self parent]) {
        [WMLog warning:"Attempt to perform parent action failed - parent is null"];
        return nil;
    }
    return [[self parent] invokeDirectActionNamed:actionName inContext:context];
}

- (Boolean) bindingIsComponent:(id)binding {
    if (typeof binding != "object") {
        return false;
    }
    if (typeof binding["_index"] != "undefined") {
        return true;
    }
    binding['_IS_COMPONENT'] = binding['_IS_COMPONENT'] || [self _bindingIsComponent:binding];
    return binding['_IS_COMPONENT'];
}

- (Boolean) _bindingIsComponent:(id)binding {
    if (binding['type'] == "COMPONENT") { return true }
    if (SYSTEM_BINDING_TYPES[binding['type']]) { return false }
    return true;
}

- _appendErrorString:(id)error toResponse:(id)response {
    [response appendContentString:"<span style='border: 2px solid red; padding: 3px; font-weight: bold; font-family: Verdana,Arial,Helvetica;'>" + error + "</span>"];
}

- (Boolean) hasCompiledResponse {
    return false;
}

// Override this if you need to use a different mechanism than
// http 30x to redirect (facebook!), action must call this
// rather than returning the URL directly. Undecided if this
// should actually be further up, further down ... hmmm
//
- redirectToUrl:(id)url {
    return url;
}

- (Boolean) isNastyOldBrowser {
    return [self isUnsupportedBrowser]; // :)
}

// override and do what you want here; this just filters
// out some shitty browsers.
- (Boolean) isUnsupportedBrowser {
    var userAgent = [[self context] userAgent];
    if ([self isMacIE:userAgent]) { return true }
    var match = userAgent.match(/^([^\/]+)\/([0-9\.]+)/);
    if (!match) { return true }
    var majorCompatibility = match[1];
    var majorVersion = match[2];

    var im = userAgent.match(/MSIE ([0-9\.]+)/);
    var ieVersion;
    if (im) { ieVersion = im[1] }
    if (majorCompatibility == "Mozilla" && majorVersion < 5) {
        if (ieVersion < 5) { return true }
        return false;
    }
    // Opera just graduated from "not-sucking" school.
    // return 1 if ($majorCompatibility eq "Opera");
    if (majorVersion < 5) { return true }
    if (userAgent.match(/Gecko\/2003/)) { return true }
    return false;
}

- (Boolean) isMacIE:(id)userAgent {
    if (userAgent.match(/Mac/)) {
        if (userAgent.match(/MSIE/)) { return true }
    }
    return false;
}

//-------------------------------------------------------------
// These are private helper functions that I'm gathering up
// and will get rid of as many as possible.
//-------------------------------------------------------------
//
+ (id) __templateNameFromComponentName:(id)componentName {
    //componentName =~ s/::/\//g;
    return componentName + ".html";
}

/*
+ (id) __templateNameFromContext:(id)context {
    var templateName = [WMComponent __templateNameFromComponentName:[context targetComponentName]];
    [WMLog info:"template name is " + templateName];
    return templateName;
}

+ (WMResponse) __responseFromContext:(id)context {
    var templateName = [WMComponent __templateNameFromContext:context];
    var response = [WMResponse new];
    var template = [[context siteClassifier] bestTemplateForPath:templateName andContext:context];
    if (!template) { return response }
    [response setTemplate:template];
    return response;
}
*/

// FIXME!  What should this be without perl namespacing!?
- (id) componentName {
    if (!_componentName) {
        var className = [self className];
        // freaky hack
        if (!className.match(/^WMTest/)) {
            className = className.replace(/^WM/, "");
        }
        _componentName = className;
    }
    return _componentName;
}

- (id) componentNameRelativeToSiteClassifier {
    if (!_componentNameRelativeToSiteClassifier) {
        var sc = [self _siteClassifier];
        var componentName = [sc relativeNameForComponentName:[self componentName]];
        _componentNameRelativeToSiteClassifier = componentName;
    }
    return _componentNameRelativeToSiteClassifier;
}

- (id) hierarchy {
    return _hierarchy;
}

- (void) setHierarchy:(id)_v {
    _hierarchy = _v;
}

// - componentNameSpace {
//     var className = ref self;
//     className =~ m/(.+)::Component/;
//     return 1;
// }

// where is this used?
//
//+ parentClasses {
//    return [ eval '@' + className + '::ISA' ];
//}
//

- (Boolean) isSystemComponent {
    var className = [self class];
    return (className.match(/^WM/));
}

- (Boolean) hasValuesForFields:(id)fields inContext:(id)context {
    for (var i=0; i < fields.length; i++) {
        var field = fields[i];
        if ([context formValueForKey:field] == "") {
            return false;
        }
    }
    return true;
}

// FIXME move into some "Form" component subclass
// override this!
- (Boolean) hasValidFormValues:(id)context {
    return true;
}

- (WMRenderState) _renderState { return _renderState }
- (void) _setRenderState:(WMRenderState)_value { _renderState = _value }

// If you override this and return true, then bindings of the form
// <binding:foo_bar /> will try to access key "foo_bar" on the
// component if no specific binding for that key is found.
//
- (Boolean) allowsDirectAccess {
    return false;
}

- (id) tagAttributes { return _tagAttributes }
- (void) setTagAttributes:(id)_value { _tagAttributes = _value }

- (id) tagAttributeForKey:(id)key {
    if (!_tagAttributes) { return nil }
    var tagAttribute = _tagAttributes[key];
    if (!tagAttribute) { return nil }
    return [self _evaluateKeyPathsInTagAttributes:tagAttribute onComponent:self];
}

- (id) _evaluateKeyPathsInTagAttributes:(id)tagAttribute onComponent:(id)component {
    if (!tagAttribute || !component) { return "" }
    var count = 0;
    var match;
    var ekpre = new RegExp("\$\{([^}]+)\}");
    while (match = tagAttribute.match(ekpre)) {
        var keyValuePath = match[1];
        var _value = [component valueForKeyPath:keyValuePath] || [component valueForKeyPath:'parent.' + keyValuePath];
        //[WMLog debug:"tagAttributeForKey - Found keyValuePath of " + keyValuePath + " and that returned " + value];
        //[WMLog debug:"parent is " + [component parent]];
        var rr = new RegExp("\$\{" + _p_quotemeta(keyValuePath) + "\}");
        tagAttribute.replace(rr, _value);
        //Avoiding the infinite loop...just in case
        if (count++ > 100) { break }
    }
    return tagAttribute;
}

// TODO: this is a stop-gap solution; these should be read from
// the default bindings file, specified in the app config.
- (id) _defaultBindings {
    return {
        tag_attributes: {
            type: "ATTRIBUTES",
        },
        javascript_root: {
            type: "STRING",
            value: objj("[[self application] systemConfigurationValueForKey:'JAVASCRIPT_ROOT']"),
        },
        is_first_time_rendered: {
            type: "BOOLEAN",
            value: 'isFirstTimeRendered',
        },
        unique_id: {
            type: "STRING",
            value: 'uniqueId',
        },
        parent_binding_name: {
            type: "STRING",
            value: 'nestedBindingPath',
        },
        has_required_message: {
            type: "BOOLEAN",
            value: 'isRequiredMessage',
        },
        is_required: {
            type: "BOOLEAN",
            value: 'isRequired',
        },
        required_message: {
            type: "STRING",
            value: 'isRequiredMessage',
        },
    };
}

// New conveniences; these are designed to help clean up the whole
// life-cycle of components from instantiation through to rendering
//

+ (WMComponent) instanceForRequest:(id)request {
    var context = [WMContext contextForRequest:request];
    var targetComponentName = [context targetComponentName];
    if (!targetComponentName) { return nil }
    var siteClassifier = [context siteClassifier];
    if (!siteClassifier) { return nil }
    var component = [siteClassifier componentForName:targetComponentName andContext:context];
    return component;
}

// Helpers to assist in the porting of this stuff to objj
// FIXME:kd  This caches the template!
/*
- (WMTemplate) template {
    if (_template) { return _template }
    _template = [[self _siteClassifier] bestTemplateForPath:[self templateName] andContext:[self context]];
    return _template;
}
*/
- (WMTemplate) template {
    return [[self _siteClassifier] bestTemplateForClass:[self class] inContext:[self context]];
}

// This helper just makes a default response
- (WMResponse) response {
    return [WMResponse new];
}

- (id) render {
    return [self renderWithParameters:nil];
}

// This bypasses the generation of a response object for the consumer
// and just renders it into the response object and returns the
// rendered text.
//
- (id) renderWithParameters:(id)parameters {
    parameters = parameters || {};
    var context = parameters['context'] || [self context];
    if (!context) {
        // build a new request object
        var request = [WMOfflineRequest new];
        // build a URI representing the component with sensible defaults
        var cn = [self componentNameRelativeToSiteClassifier];
        var uri = [
                [[self application] configurationValueForKey:"URL_ROOT"],
                parameters['siteClassifierName'] || [[self _siteClassifier] name],
                parameters['language'] || [[self application] configurationValueForKey:"DEFAULT_LANGUAGE"],
                cn,
                [[self application] configurationValueForKey:"DEFAULT_DIRECT_ACTION"],
        ].join("/");
        [request setUri:uri];
        [request setApplicationName:[[self application] name]];
        context = [WMContext contextForRequest:request];
    }
    _context = context;
    var response = parameters['response'] || [self response];
    [self appendToResponse:response inContext:context];
    return [response content];
}

// To return a JSON'ed object instead of a response
+ (id) json:(id)wrapper {
    var response = [WMResponse new];
    var t = [WMUtility jsonFromObject:object andKeys:keys];
    if (wrapper) {
        t = wrapper + "(" + t + ");";
    }
    [response appendContentString:t];
    [response setContentType:"text/javascript"];
    return response;
}

// I18N
//
//@import <WM/I18N>;
//+ _s {
//    var (self, args) = @_;
//    return WMI18N._s(args);
//}

+ COMPONENT_CONTENT_MARKER {
    return COMPONENT_CONTENT_MARKER;
}

+ TAG_ATTRIBUTE_MARKER {
    return TAG_ATTRIBUTE_MARKER;
}

+ REGION_TAG_MARKER {
    return REGION_TAG_MARKER;
}

@end
