/* --------------------------------------------------------------------
 * WM - Web Framework and ORM heavily influenced by WebObjects & EOF
 * The MIT License
 *
 * Copyright (c) 2010 kd
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

@import "WMLog.j"
@import "WMDictionary.j"
@import "Helpers.js"

var PRINTF = require("printf");
var FILE = require("file");

var TEMPLATE_CACHE = {};
var TEMPLATE_AGE_CACHE = {};

// FIXME: make these exception types
var ERRORS = {
    INCLUDED_TEMPLATE_NOT_FOUND: "Could not find included template %s",
    NO_MATCHING_START_TAG_FOUND: "No matching start tag found for %s",
    NO_MATCHING_END_TAG_FOUND: "No matching end tag found for %s",
    BADLY_NESTED_BINDING: "Badly nested binding %s inside %s at position %d",
    ILLEGAL_NESTING_OF_SAME_NAMED_BINDING: "Illegal nesting of same-named binding %s",
    BINDING_NOT_FOUND: "Binding %s not found",
};

@implementation WMTemplate : WMObject
{
    id content @accessors;
    id contentElementCount;
    id language @accessors;
    id mimeType @accessors;
    id encoding @accessors;
    id parseErrors @accessors;
    id paths @accessors;
    id fullPath @accessors;
    id templateSource @accessors;
}

- (id) init {
    [super init];
    content = [];
    parseErrors = [];
    paths = [];
    return self;
}

+ (id) newWithName:(id)n andPaths:(id)ps shouldCache:(id)c {
    return [[self new] initWithName:n andPaths:ps shouldCache:c];
}

- (id) initWithName:(id)n andPaths:(id)ps shouldCache:(id)c {
    [self init]
    if (paths) {
        [self setPaths:ps];
    }
    if (n) {
        var fp = [WMTemplate firstMatchingFileWithName:n inPathList:[self paths]];
        if (!fp) {
            //[CPException raise:"CPException" reason:"Failed to find template " + n + " in paths " + [self paths]];
            [WMLog debug:"Failed to find template " + n + " in paths " + [self paths]];
            return nil;
        }

        if ([WMTemplate hasCachedTemplateForPath:fp]) {
            return [WMTemplate cachedTemplateForPath:fp];
        }
        [self initWithFile:fp];
        if (c) {
            [WMTemplate addToCache:self];
        }
    }

    return self;
}

- (id) initWithFile:(id)fp {
    [self setFullPath:fp]
    [self setTemplateSource:[WMTemplate contentsOfFileAtPath:fp]];
    [self setLanguage:[self languageFromPath:fp]];
    [self setMimeType:[self mimeTypeFromPath:fp]];
    [self setEncoding:'utf-8'];
    [self parseTemplate];
    // source is not needed now, so blow it away
    [self setTemplateSource:nil];
    return self;
}

- initWithString:(id)st inLanguage:(id)l {
    [self setFullPath:nil];
    [self setTemplateSource:st];
    [self setLanguage:l];
    [self parseTemplate];
    [self setTemplateSource:nil];
    return self;
}

- (void) setContent:(id)c {
    content = c;
    contentElementCount = content.length;
}

- (id) contentElementAtIndex:(id)index {
    return content[index];
}

- (id) contentElementsInRange:(id)start :(id)end {
    return content.splice(start, end);
}

- contentElementCount {
    return contentElementCount;
}

// This is the guts of it:
- (void) parseTemplate {
    [self processTemplateIncludes];
    //[self fixLogicTags];
    //[self fixLegacyTags];
    [self extractBindingTags];
    [self matchStartAndEndTags];
    [self checkSyntax];
}

// This is really deprecated - but here in case someone finds it
// useful.  There are a few uses for it, I suppose
- (void) processTemplateIncludes {
    var rei = new RegExp("(<TMPL_INCLUDE [^>]+>)", "i");
    var ren = new RegExp("NAME=\"?([^>\"]+)\"?", "i");
    var rec = new RegExp('TMPL_INCLUDE "?([^\">]+)"?', "i");
    var match;
    while (match = templateSource.match(rei)) {
        var tag = match[1];
        var filename;
        var fm;
        if (fm = tag.match(ren)) {
            filename = fm[1];
        } else {
            fm = tag.match(rec);
            if (fm) {
                filename = fm[1];
            }
        }
        var fullPath = [WMTemplate firstMatchingFileWithName:filename inPathList:[self paths]];
        if (fullPath) {
            var content = [WMTemplate contentsOfFileAtPath:fullPath];
            templateSource = templateSource.replace(tag, content);
        } else {
            var noTemplateFoundString = "<b>Couldn't find included file " + filename + "</b>";
            templateSource = templateSource.replace(tag, noTemplateFoundString);
            [self addParseError:"INCLUDED_TEMPLATE_NOT_FOUND", filename];
        }
    }
    [self setTemplateSource:templateSource];
}

- (void) extractBindingTags {
    var templateSource = [self templateSource];
    var tags = {};
    var content = [];
    // most important are binding tags
    // yikes:
    var ere = new RegExp("(<\/?binding[^:]*:[A-Za-z0-9_]+ ?[^>]*>|<key(path)?[\t\r\n ]+([^\t\r\n >]+)[\t\r\n ]*\/?>)", "i");
    var match;
    while (match = templateSource.match(ere)) {
        var tag = match[1];
        var keypath = match[3];
        var quotedtag = tag;
        //quotedtag =~ s/([\(\)\?\*\+\"\'\$\&\]\[\|])/\\1/g;
        var bits = _p_2_split(tag, templateSource);
        var beforeTag = bits[0];
        var afterTag = bits[1];
        content.push(beforeTag);
        if (keypath) {
            // TODO:kd implement this with some objectsssss
            content.push({
                //IS_END_TAG: ? true : false,
                IS_END_TAG: false,
                KEY_PATH: keypath,
                BINDING_TYPE: "KEY_PATH",
            });
        } else {
            var newTagEntry = [WMTemplate newTagEntryForTag:tag];
            content.push(newTagEntry);
        }
        templateSource = afterTag;
    }
    content.push(templateSource);
    [self setContent:content];
}

- (void) matchStartAndEndTags {
    for (var i = 0; i<[self contentElementCount]; i++) {
        var index = [self contentElementAtIndex:i];
        if (typeof index != "object") { continue }
        var bindingName = index['BINDING_NAME'];
        if (index['IS_END_TAG']) { continue }
        if (index['BINDING_TYPE'] == "BINDING_ELSE") { continue }
        var nestingDepth = 0;
        //otherwise scan forward for an end tag
        //[WMLog debug:index.toSource()];
        for (var j = i+1; j<[self contentElementCount]; j++) {
            var contentElement = [self contentElementAtIndex:j];
            if (typeof contentElement != "object") { continue }
            //[WMLog debug:contentElement.toSource()];
            if (contentElement['BINDING_NAME'] != bindingName) { continue }
            //[WMLog debug:"name ok"];
            if (contentElement['BINDING_TYPE'] != index['BINDING_TYPE'] &&
                contentElement['BINDING_TYPE'] != "BINDING_ELSE") {
                continue;
            }
            //[WMLog debug:"type is same or type is else"];
            if (contentElement['IS_END_TAG']) {
                if (nestingDepth == 0) {
                    index['END_TAG_INDEX'] = j;
                    contentElement['START_TAG_INDEX'] = i;
                    if (index['ELSE_TAG_INDEX']) {
                        var elseTag = [self contentElementAtIndex:index['ELSE_TAG_INDEX']];
                        if (elseTag) {
                            elseTag['END_TAG_INDEX'] = j;
                            elseTag['START_TAG_INDEX'] = i;
                        }
                    }
                    break;
                } else {
                    nestingDepth--;
                }
            } else {
                if (contentElement['BINDING_TYPE'] == "BINDING_ELSE") {
                    //[WMLog debug:"it's an else"];
                    if (index['BINDING_TYPE'] == "BINDING_IF" || index['BINDING_TYPE'] == "BINDING_UNLESS") {
                        //[WMLog debug:"setting the else tag index to " + j];
                        index['ELSE_TAG_INDEX'] = j;
                    }
                } else {
                    //IF::Log::debug("Found nesting of same-named binding: $bindingName");
                    //$self->addParseError("ILLEGAL_NESTING_OF_SAME_NAMED_BINDING", $bindingName);
                    nestingDepth++;
                }
            }
        }
        if (nestingDepth > 0 && (index['BINDING_TYPE'] == "BINDING_IF" ||
                                  index['BINDING_TYPE'] == "BINDING_LOOP" ||
                                  index['BINDING_TYPE'] == "BINDING_UNLESS")) {
            //$self->addParseError("BADLY_NESTED_BINDING", $bindingName);
        }
    }
}

- namedBindings {
    var namedBindings = [];
    var viewedBindings = {};
    for (var i=0; i < _content.length; i++) {
        var contentElement = _content[i];
        if (typeof contentElement != "object") { continue }
        var bindingName = contentElement['BINDING_NAME'];
        if (viewedBindings[bindingName]) { continue };
        //if (bindingName =~ /^__LEGACY__( + *)$/) {
        //    push (@namedBindings, 1);
        //} else {
            namedBindings.push("binding:" + bindingName);
        //}
        viewedBindings[bindingName] = true;
    }
    return namedBindings;
}

// static methods:
// these are mostly helpers to unpack bits of the template.  dirty.

+ (id) bindingNameFromTag:(id)tag {
    var bre = new RegExp("^<binding:([A-Za-z0-9_]+).*>");
    var match;
    if (match = tag.match(bre)) {
        return match[1];
    }
    // if (tag =~ /^<tmpl_[^ ]* [^ ]*binding:([A-Za-z0-9_]+) + *>/i) {
    //     return 1;
    // }

    // tag =~ s/ESCAPE=HTML//i;
    // tag =~ s/NAME=//i;
    // if (tag =~ /^<tmpl_[^ ]* +"?([A-Za-z0-9_]+) + *>/i) { #"
    //     return "__LEGACY__" + 1;
    // }
    throw [CPException raise:"CPException" reason:"Couldn't parse binding name from " + tag];
    return "";
}

+ (id)newTagEntryForTag:(id)tag {
    tag = tag.replace(/(?:^<|\/?>$)/g, "");
    var bre = new RegExp("^(\/?)(binding[^:]*):([A-Za-z0-9_]+) ?(.*)\s*$", "i");
    var match = tag.match(bre);
    if (match) {
        var isEndTag = match[1];
        var bindingTagType = match[2];
        var bindingName = match[3];
        var attributes = match[4];
        var bits = [WMTemplate explicitBindingAndAttributeHashFromName:bindingName andAttributes:attributes];
        var binding = bits.shift();
        var attributeHash = bits.shift();
        return {
            IS_END_TAG: isEndTag? true: false,
            BINDING_TYPE: bindingTagType.toUpperCase(),
            BINDING_NAME: bindingName,
            ATTRIBUTES: attributes,
            ATTRIBUTE_HASH: attributeHash,
            // BINDING => $binding,
        };
    }
    throw [CPException raise:"CPException" reason:"Couldn't create binding info from " + tag];
}

+ (id) explicitBindingAndAttributeHashFromName:(id)name andAttributes:(id)attributes {
    //[WMLog debug:"Processing " + name + " / " + attributes];
    //return (undef, $attributes) unless $attributes =~ /definition=\"explicit\"/i;
    //
    var attributeHash = {};
    // TODO this should really parse the attributes using Text::Balanced or something
    // because this method won't correctly parse backquoted quotes.
    var re1 = new RegExp('([a-zA-z0-9:-_]+)="([^">]+)"');
    var re2 = new RegExp("([a-zA-Z0-9:-_]+)='([^'>]+)'");
    var re3 = new RegExp("([a-zA-Z0-9:-_]+)=([^\s>]+)/");
    var match;
    while (1) {
        match = attributes.match(re1);
        match = match || attributes.match(re2);
        match = match || attributes.match(re3);
        if (!match) { break }
        attributeHash[match[1]] = match[2];
        attributes = attributes.replace(match[0], "");
        //[WMLog debug:attributeHash.toSource()];
    }
    var binding = { _NAME: name };
    for (var key in attributeHash) {
        //IF::Log::debug("Found attribute $key of tag $name");
        if (key == "definition") { continue }
        var value = attributeHash[key];
        value = value.replace(/\&gt;/g, ">");
        if (key == "type" || key == "value" || key == "outgoingTextToHTML" || key == "format" ||
            key == "list" || key == "item") {
            binding[key] = value;
        } else {
            if (key.match(/^binding:/)) {
                var newKey = key;
                newKey = newKey.replace(/^binding:/, "");
                binding['bindings'][newKey] = value;
                delete attributeHash[newKey];
            }
        }
    }

    // TODO : rewrite this method so that we don't need this check here:
    if (!attributeHash['definition'] || (attributeHash['definition'] != "explicit")) {
        return [null, attributeHash];
    }
    return [binding, attributeHash];
}

+ (id) splitTemplateOnMatchingCloseTag:(id)tag forTag:(id)html {
    var startHtml = "";
    var tagDepth = 1;
    //IF::Log::debug("Splitting on matching end tag for $tag");
    while (1) {
        var re = new RegExp("(<" + tag + "[^>]*>)", "i");
        var match = html.match(re);
        var startTag = match[1];
        var ts = new RegExp("<" + tag + "[^>]*>", "i");
        var te = new RegExp("<\/" + tag + ">", "i");
        var lookingForStart = _p_2_split(ts, html);
        var lookingForEnd = _p_2_split(te, html);

        if (lookingForStart.length == 1 && lookingForEnd.length == 1) {
            return [nil, nil];
        }

        //IF::Log::debug($html);

        if (lookingForEnd[0].length < lookingForStart[0].length) {
            tagDepth -= 1;
            html = lookingForEnd[1];
            startHtml = startHtml + lookingForEnd[0];
            if (tagDepth > 0) {
                startHtml = startHtml + "</" + tag + ">";
            }
        } else {
            tagDepth += 1;
            html = lookingForStart[1];
            startHtml = startHtml +  lookingForStart[0] + startTag;
        }

        if (tagDepth <= 0) {
            return [startHtml, html];
        }
    }
}

+ (id) firstMatchingFileWithName:(id)file inPathList:(id)paths {
    paths = paths || [];
    var re = new RegExp("^\/");
    if (file.match(re)) {
        paths.unshift("");
    }
    for (var i=0; i<paths.length; i++) {
        var directory = paths[i];
        var fullPathToFile = file;
        if (directory != "") {
            fullPathToFile = directory + "/" + file;
        }
        if ([WMTemplate hasCachedTemplateForPath:fullPathToFile]) {
            return fullPathToFile;
        }
        //[WMLog debug:"Checking for " + file + " at " + fullPathToFile];
        if (!FILE.exists(fullPathToFile)) { continue }
        //[WMLog debug:"Found template " + file + " at " + fullPathToFile];
        return fullPathToFile;
    }
    return nil;
}

+ (id) contentsOfFileAtPath:(id)fullPathToFile {
    var f;
    if (f = FILE.open(fullPathToFile)) {
        var contents = f.read();
        //if (var decodedContents = decode_utf8(contents)) {
        //    contents = decodedContents;
        //} else {
        //    [WMLog error:"Template not valid utf8: " + fullPathToFile];
        //        if length (contents);
        //}
        f.close();
        return contents;
    } else {
        [IFLog error:"Error opening " + fullPathToFile];
        return nil;
    }
}

+ (void) addToCache:(id)template {
    var path = [template fullPath];
    TEMPLATE_CACHE[path] = template;
    var stat = FILE.stat(path);
    if (stat) {
        //[WMLog debug:"path " + path + " time " + stat['mtime']];
        TEMPLATE_AGE_CACHE[path] = stat['mtime'];
    } else {
        throw [CPException raise:"CPException" reason:"Couldn't get age of file " + [template fullPath]];
    }
    //[WMLog debug:"Stashed cached template for " + path + " in template cache"];
}

+ (Boolean) hasCachedTemplateForPath:(id)path {
    var stat = FILE.stat(path);
    if (!stat) {
        throw [CPException raise:"CPException" reason:"Couldn't get age of file " + path];
    }
    var currentAge = stat['mtime'];
    return [WMTemplate cachedTemplateForPath:path] && TEMPLATE_AGE_CACHE[path]
         && (currentAge.getTime() == TEMPLATE_AGE_CACHE[path].getTime());
}

+ (WMTemplate) cachedTemplateForPath:(id)path {
    return TEMPLATE_CACHE[path];
}

- (id) languageFromPath:(id)fullPath {
    var ps = paths;
    if (!ps || ps.length == 0) {
        ps = [fullPath];
    }
    var sls = ps.sort(function (a, b) { b.length - a.length });
    for (var i=0; i<sls.length; i++) {
        var path = sls[i];
        var re = new RegExp("^" + path);
        if (fullPath.match(re)) {
            var lre = new RegExp(".*\/([A-Za-z][A-Za-z])$");
            var match = path.match(lre);
            if (match) { return match[1] }
        }
    }
    return null;
}

// This is pretty cheesy, but it works 99.9999% of the time...
- (id) mimeTypeFromPath:(id)fullPath {
    var type;
    if (fullPath.match(/\.html?$/)) { return 'text/html' }
    if (fullPath.match(/\.txt$/)) { return 'text/plain' }
    [IFLog warning:'Failed to deduce template content type.  Defaulting to html'];
    return 'text/html';
}

// We need to beef this up to produce real error objects but for now descriptions
// will do
//
- (void) addParseError:(id)error, ... {
    var errorDescription = ERRORS[error];
    parseErrors.push(PRINTF.sprintf(errorDescription, arguments.slice(2)));
}

- hasParseErrors {
    return parseErrors.length > 0;
}

- (id) checkSyntax {
    for (var i=0; i<[self contentElementCount]; i++) {
        //print "$i / ";
        var element = [self contentElementAtIndex:i];
        if (typeof element != 'object') { continue }
        var endTagIndex = element['BINDING_TYPE'] != "BINDING" ?
                                    element['ELSE_TAG_INDEX'] || element['END_TAG_INDEX'] :
                                    element['END_TAG_INDEX'];
        if (endTagIndex) {
            var openedTags = {};
            for (var j=i+1; j<endTagIndex; j++) {
                var checkedElement = [self contentElementAtIndex:j];
                if (typeof checkedElement != 'object') { continue }
                if (checkedElement['END_TAG_INDEX'] ||
                        (checkedElement['ELSE_TAG_INDEX'] &&
                         checkedElement['BINDING_TYPE'] != "BINDING")) {
                    openedTags[j] = 1;
                }
                if (checkedElement['START_TAG_INDEX']) {
                    if (checkedElement['IS_END_TAG']) {
                        var startTag = [self contentElementAtIndex:checkedElement['START_TAG_INDEX']];
                        if (startTag['ELSE_TAG_INDEX']) {
                            delete openedTags[startTag['ELSE_TAG_INDEX']];
                        } else {
                            delete openedTags[checkedElement['START_TAG_INDEX']];
                        }
                    } else {
                        delete openedTags[checkedElement['START_TAG_INDEX']];
                    }
                }
            }
            for (var index in openedTags) {
                var badlyNestedTag = [self contentElementAtIndex:index];
                [self addParseError:"BADLY_NESTED_BINDING", badlyNestedTag['BINDING_NAME'],
                                    element['BINDING_NAME'], index]
            }
        } else {
            if (element['IS_END_TAG']) {
                if (!element['START_TAG_INDEX']) {
                    [self addParseError:"NO_MATCHING_START_TAG_FOUND", element['BINDING_NAME']];
                }
            } else if (element['BINDING_TYPE'] == "BINDING_IF" ||
                       element['BINDING_TYPE'] == "BINDING_UNLESS" ||
                       element['BINDING_TYPE'] == "BINDING_LOOP") {
                [self addParseError:"NO_MATCHING_END_TAG_FOUND", element['BINDING_NAME']];
            }
        }
    }
}

+ (id) errorForKey:(id)key, ... {
    return PRINTF.sprintf(ERRORS[key], arguments.slice(3)) || key;
}

// this method is the most complicated thing in this whole friggin project
/*
+ (id) splitTemplateOnMatchingElseTag:(id)html {
    var startHtml = "";
    var tagDepth = 1;

    while (1) {
        var startTag;
        var endTag;
        var lookingForStart;
        var lookingForEnd;
        if (html =~ /(<(tmpl_if|tmpl_unless)[^>]*>)/i) {
            startTag = 1;
            //IF::Log::debug("Found start tag $startTag");
            lookingForStart = split(/startTag/, html, 2);
        } else {
            lookingForStart[0] = html;
        }

        if (html =~ /(<\/(tmpl_if|tmpl_unless)>)/i) {
            endTag = 1;
            IF::Log::debug("Found end tag $endTag");
            lookingForEnd = split(/endTag/, html, 2)
        } else {
            lookingForEnd[0] = html;
        }

        if (tagDepth <= 1) {
            var lookingForElse = split(/<tmpl_else>/i, html, 2);
            if (length(lookingForElse[0]) < length(lookingForEnd[0]) &&
                length(lookingForElse[0]) < length(lookingForStart[0])) {
                startHtml .= lookingForElse[0];
                html = lookingForElse[1];
                //IF::Log::debug("Returning split at TMPL_ELSE: ");
                //IF::Log::debug($startHtml);
                //IF::Log::debug($html);
                //
                return (startHtml, html);
            }
        }

        //return ($html, undef) if ($lookingForStart[0] eq $html || $lookingForEnd[0] eq $html);
        if (length(lookingForStart[0]) == length(lookingForEnd[0])) {
            // found neither a start nor an end tag
            return (html, "");
        }

        if (length(lookingForEnd[0]) < length(lookingForStart[0])) {
            tagDepth -= 1;
            html = lookingForEnd[1];
            startHtml .= lookingForEnd[0];
            if (tagDepth > 0) {
                startHtml .= endTag;
            }
        } else {
            tagDepth += 1;
            html = lookingForStart[1];
            startHtml .= lookingForStart[0] + startTag;
        }
        if (tagDepth <= 0) {
            return (startHtml, html);
        }
    }
}
*/

/*
- dump {
    for (var i=0; i<[self contentElementCount]; i++) {
        var element = [self contentElementAtIndex:i](i);
        if (typeof element == 'object') {
            var description = PRINTF.sprintf("02d : %s", i, element['BINDING_TYPE'] + " " + element['BINDING_NAME']);
            if (element['ELSE_TAG_INDEX']) {
                description .= " ELSE: " + element['ELSE_TAG_INDEX'];
            }
            if (element['END_TAG_INDEX']) {
                description .= " END: " + element['END_TAG_INDEX'];
            }

            if (element['IS_END_TAG']) {
                description .= " -END";
                if (element['START_TAG_INDEX']) {
                    description .= " START: " + element['START_TAG_INDEX'];
                } else {
                    IFLog.error("This item has no START_TAG_INDEX:");
                }
            }
            IFLog.debug(description);
            if (element['BINDING']) {
                IFLog.dump(element['BINDING']);
            }
        } else {
            IFLog.debug(sprintf("02d : TEXT %s", i, element));
        }
    }
}
*/


/*
- (void) fixLogicTags {
    var templateSource = [self templateSource];
    templateSource = replace(/TMPL_IF[ ]+/i, "TMPL_IF ");
    templateSource = replace(/TMPL_UNLESS[ ]+/i, "TMPL_UNLESS ");
    templateSource = replace(/TMPL_LOOP[ ]+/i, "TMPL_LOOP ");

    var logicTagMap = {
        tmpl_if: "BINDING_IF",
        tmpl_unless: "BINDING_UNLESS",
        tmpl_loop: "BINDING_LOOP",
    };

    for (var logicTag in logicTagMap) {
        var tre = new RegExp("(<" + logicTag + " [^>]+>)", "i");
        var match;
        while (match = templateSource.match(tre)) {
            var tag = match[1];
            var bits = _p_2_split(tag, templateSource);
            var beforeTag = bits[0];
            var afterTag = bits[1];
            bits = [WMTemplate splitTemplateOnMatchingCloseTag:afterTag forTag:logicTag];
            var content = bits.shift();
            var afterContent = bits.shift();
            // read forward for matching end tag
            if (!content && !afterContent) {
                [self addParseError:"NO_MATCHING_END_TAG_FOUND", tag];
            }
            var bindingName = [WMTemplate bindingNameFromTag:tag];
            if (logicTag != "tmpl_loop") {
                bits = [WMTemplate splitTemplateOnMatchingElseTag:content];
                var yesContent = bits.shift();
                var noContent = bits.shift();
                if (noContent) {
                    content = yesContent + "<BINDING_ELSE:" + bindingName + ">" + noContent;
                }
            }
            templateSource = beforeTag + "<" + logicTagMap[logicTag] + ":" + bindingName + ">" + content + "</" + logicTagMap[logicTag] + ":" + bindingName + ">" + afterContent;
        }
    }

    [self setTemplateSource:templateSource];
}
*/

/* LEGACY stuff should be punted
- (void) fixLegacyTags {
    var templateSource = [self templateSource];

    while (templateSource =~ /(<tmpl_var [^>]+>)/i) {
        var tag = 1;
        var bindingName = bindingNameFromTag(tag);
        if (bindingName =~ /__LEGACY__TC_( + *)$/i) {
            [self addNamedComponent:1];
        }
        //IF::Log::debug("Found legacy tag: $bindingName");
        templateSource =~ s/tag/<BINDING:bindingName>/ig;
    }

    [self setTemplateSource:templateSource](templateSource);
}
*/

@end
