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

@import "Object.j"
@import "PrimaryKey.j"

var UTIL = require("util");

@implementation WMEntityClassDescription : WMObject
{
    Object modelData;
    Object attributeToColumnMappings;
    CPString name @accessors;
    WMPrimaryKey _primaryKeyDefinition;
}


- initWithModelData:(id)md {
    //[WMLog dump:md];
    [self init];
    modelData = md;
    attributeToColumnMappings = {};
    for (attributeName in modelData['ATTRIBUTES']) {
        var attribute = modelData['ATTRIBUTES'][attributeName];
        attributeToColumnMappings[attribute.ATTRIBUTE_NAME] = attribute.COLUMN_NAME;
    }
    return self;
}

- init {
    /* initialise instance */
    return [super init]
}

- relationships {
    var relationships = modelData.RELATIONSHIPS || {}
    if ([self parentEntityClassName]) {
        relationships = UTIL.update(relationships, [[self parentEntityClassDescription] relationships]);
    }
    return relationships;
}

- mandatoryRelationships {
    var mandatoryRelationships = [];
    for (relationshipName in [self relationships]) {
        var relationship = [self relationshipWithName:relationshipName];
        if (!relationship.IS_MANDATORY) {
            mandatoryRelationships[mandatoryRelationships.length] = relationship;
        }
    }
    return mandatoryRelationships;
}

- relationshipWithName:(id)relationshipName {
    var relationship = [self relationships][relationshipName];
    if (!relationship && [self parentEntityClassName]) {
        relationship = [[self parentEntityClassDescription] relationshipWithName:relationshipName];
    }
    var r = [WMRelationshipModelled newFromModelEntry:relationship withName:relationshipName];
    return r;
}

- watchedAttributes {
    return modelData['WATCHED_ATTRIBUTES'] || [WMArray new];
}

- attributes {
    return modelData['ATTRIBUTES'] || [WMDictionary new];
}

- allAttributeNames {
    return UTIL.keys(attributeToColumnMappings);
}

- allAttributes {
    return UTIL.values([self attributes]);
}

- defaultValueForAttribute:(id)attributeName {
    var attribute = [self attributeWithName:attributeName];
    return attribute.DEFAULT;
}

- attributeWithName:(id)attributeName {
    // TODO - make this a bit more tolerant of DB weirdness, like
    // upper/lower case column names, etc.
    return [self attributes][attributeName];
}

- hasAttributeWithName:(id)attributeName {
    if ([self attributeWithName:attributeName]) { return 1; }
    for (attributeKey in [self attributes]) {
        var attribute = [self attributes][attributeKey];
        if (attribute.ATTRIBUTE_NAME == attributeName) { return true; }
    }
    return false;
}

- columnNameForAttributeName:(id)attributeName {
    return attributeToColumnMappings[attributeName];
}

- attributeNameForColumnName:(id)columnName {
    var attribute = [self attributeForColumnName:columnName];
    if (!attribute) { return nil; }
    return attribute.ATTRIBUTE_NAME;
}

- (id)attributeForColumnName:(id)columnName {
    return [self attributeWithName:columnName];
}

- (id)hasColumnNamed:(id)columnName {
    var att = [self attributeForColumnName:columnName];
    if (att) { return true };
    return false;
}

- parentEntityClassName {
    return modelData.PARENT_ENTITY;
}

- parentEntityClassDescription {
    return [WMModel entityClassDescriptionForEntityNamed:[self parentEntityClassName]];
}

- _table {
    if (modelData.TABLE) { return modelData.TABLE; }
    return [[self aggregateEntityClassDescription] table];
}

- _primaryKey {
    if (!_primaryKeyDefinition) {
        _primaryKeyDefinition = [[WMPrimaryKey alloc] initWithKeyDefinition:modelData.PRIMARY_KEY]
    }
    return _primaryKeyDefinition;
}

/*
- aggregateKeyName {
    return self.AGGREGATE_KEY_NAME;
}

- aggregateValueName {
    return self.AGGREGATE_VALUE_NAME;
}

- aggregateEntity {
    return self.AGGREGATE_ENTITY;
}

- aggregateTable {
    return self.AGGREGATE_TABLE;
}

- aggregateQualifier {
    return self.AGGREGATE_QUALWMIER;
}
*/

- isReadOnly {
    return modelData.IS_READ_ONLY;
}

/*
- isAggregateEntity {
    return (self.AGGREGATE_TABLE || self.AGGREGATE_ENTITY || self._isGenerated );
}

- aggregateEntityClassDescription {
    if ([self aggregateEntity]) {
        return [WMModel defaultModel]->entityClassDescriptionForEntityNamed(self->aggregateEntity());
    }
    if (self._aggregateEntityClassDescription) {
        return self._aggregateEntityClassDescription;
    }

    // otherwise, create and cache an entity class description:
    var attributes = {
        ID: _attributeWithNameAndColumnNameAndSizeAndType("id", "ID", 11, "int"),
        CREATION_DATE: _attributeWithNameAndColumnNameAndSizeAndType("creationDate", "CREATION_DATE", 11, "int"),
        MODIFICATION_DATE: _attributeWithNameAndColumnNameAndSizeAndType("modificationDate", "MODIFICATION_DATE", 11, "int"),
        [self aggregateKeyName]: _attributeWithNameAndColumnNameAndSizeAndType(
                                            [self aggregateKeyName], self->aggregateKeyName(), 32, "varchar"),
        [self aggregateValueName]: _attributeWithNameAndColumnNameAndSizeAndType(
                                            [self aggregateValueName], self->aggregateValueName(), null, "text"),
    };

    var primaryKeyObject = [self _primaryKey];
    foreach var field (@{[primaryKeyObject keyFields]}) {
         attributes[field] = [self attributeWithName:field];
    }

    if ([self aggregateQualifier]) {
        attributes.QUALWMIER = [self attributeWithName:"QUALWMIER"];
    }

    var aecd = {
        TABLE: [self aggregateTable],
        PRIMARY_KEY: "ID",
        ATTRIBUTES: attributes,
        _isGenerated: 1,
    };
    self._aggregateEntityClassDescription = [WMEntityClassDescription new:aecd](aecd);
    return aecd;
}

+ formattedCreationDate:(id)time {
    var gd = [WMGregorianDate new:time](time);
    var cd = [self attributeWithName:"creationDate"];
    if (cd && cd.TYPE == "datetime") {
        return [gd sqlDateTime];
    }
    return [gd utc];
}

+ formattedModificationDate:(id)time {
    var gd = [WMGregorianDate new:time](time);
    var md = [self attributeWithName:"modificationDate"];
    if (md && md.TYPE == "datetime") {
        return [gd sqlDateTime];
    }
    return [gd utc];
}
*/

/* TODO:  This *almost* belongs here but not quite, because it
   has field names and ordering hard-coded into that is
   specific to Idealist.  We need to find a proper home
   for it, but for now, this is ok.
*/

/*
- orderedAttributes {
    // we decide on order like this:
    // 1. If there are indexed fields, we use those in order
    // 2. Check for important names like TYPE and geographic names
    // 3. All other attributes, grouped by type

    var attributes = [];
    var attributesLeftToOrder = [keys %{[self attributes]}];
    var attributeHasNotBeenOrdered = {map {_: 1} @attributesLeftToOrder};
        my $fullyIndexedFields = $self->{FULLY_INDEXED_FIELDS};
        if ($fullyIndexedFields) {
            foreach my $attribute (sort {$fullyIndexedFields->{$a} <=> $fullyIndexedFields->{$b}} keys %$fullyIndexedFields) {
                next if ($attribute =~ /\./); // skip if it's a key-path
                my $niceName = WM::Interface::KeyValueCoding::niceName($attribute);
                next unless $self->hasAttributeWithName($niceName);
                push (@$attributes, $self->attributeWithName($attribute));
                delete $attributeHasNotBeenOrdered->{uc($attribute)};
                delete $attributeHasNotBeenOrdered->{$niceName};
            }
        }

    var IMPORTANT_FIELDS = [qw(NAME TITLE FIRST_NAME LAST_NAME DESCRIPTION MISSION ADD1 ADD2 CITY STATE COUNTRY ZIP
                               URL PHONE EMAIL FAX TYPE CATEGORY CONTACT_NAME CONTACT_EMAIL
                               ID CREATION_DATE MODIFICATION_DATE )];

    foreach var attribute (@IMPORTANT_FIELDS) {
        next unless (attributeHasNotBeenOrdered[attribute] ||
                     attributeHasNotBeenOrdered[lc(attribute)]); // TODO: Fix all this nasty hackage
        var niceName = WMInterfaceKeyValueCoding.niceName(attribute);
        WMLog.debug(niceName);
        next unless ([self hasAttributeWithName:niceName]);
        push (@attributes, [self attributeWithName:attribute]);
        delete attributeHasNotBeenOrdered[attribute];
        delete attributeHasNotBeenOrdered[lc(attribute)];
    }

    var dateAttributes = [];
    var textAttributes = [];
    var enumAttributes = [];
    var otherAttributes = [];
    foreach var attributeLeftToBeOrdered (keys %attributeHasNotBeenOrdered) {
        var attribute = [self attributeWithName:attributeLeftToBeOrdered];
        next unless attribute;
        WMLog.debug("Couldn't find attribute for attributeLeftToBeOrdered") unless attribute;
        if (attributeLeftToBeOrdered =~ /DATE$/i) {
            push (@dateAttributes, attribute);
        } elsif (attribute.TYPE =~ /(CHAR|TEXT|BLOB)/i) {
            push (@textAttributes, attribute);
        } elsif (attribute.TYPE =~ /^ENUM$/i) {
            push (@enumAttributes, attribute);
        } else {
            push (@otherAttributes, attribute);
        }
    }
    push (@attributes, @dateAttributes, @textAttributes, @enumAttributes, @otherAttributes);
    return attributes;
}
*/

/*===============================================
   Geographic Location Handling ..
*/

/*
- _geographicAttributeKeys {
    return self.GEOGRAPHIC_ATTRIBUTE_KEYS;
}

- hasGeographicData {
    return defined([self _geographicAttributeKeys]);
}

- geographicCountryNameKey {
    return [self _geographicAttributeKeys]->{COUNTRY_NAME};
}

- geographicStateNameKey {
    return [self _geographicAttributeKeys]->{STATE_NAME};
}

- geographicCityNameKey {
    return [self _geographicAttributeKeys]->{CITY_NAME};
}

- geographicAddress1NameKey {
    return [self _geographicAttributeKeys]->{ADDRESS1_NAME};
}

- geographicAddress2NameKey {
    return [self _geographicAttributeKeys]->{ADDRESS2_NAME};
}

*/

/* TODO: same for geographicMetroAreaNameKey(), geographicSuburbNameKey(), and geographicAreaNameKey() */


/*=============================================== */

+ _attributeWithName:(id)attributeName andColumnName:(id)columnName andSize:(id)size andType:(id)type {
    /* AndElvesAndOrcsesAndMen...Gollum!Gollum! */
    return {
        'DEFAULT': '',
        'EXTRA': '',
        'SIZE': size,
        'NULL': '',
        'ATTRIBUTE_NAME': attributeName,
        'VALUES': [],
        'COLUMN_NAME': columnName,
        'KEY': '',
        'TYPE': type,
    };
}

/* this breaks down the keypath by traversing it from relationship
   to relationship, and returns the target ecd and attribute
   TODO rewrite the translation code to use this.  That's a bit
   tricky because it'll require some stuff to be done during keypath
   traversal
*/

- parseKeyPath:(id)keyPath withSQLExpression:(id)sqlExpression andModel:(id)model {
    var oecd = self;  // original ecd
    var cecd = self;  // current ecd

    model = model || [WMModel defaultModel];

    // Figure out the target ecd for the qualifier by looping through the keys in the path

    var bits = [keyPath componentsSeparatedByString:/\./];

    if ([bits count] == 0) {
        bits = [[WMArray alloc] initWithObjects:keyPath];
    }
    var qualifierKey;

    for (var i=0; i<[bits count]; i++) {
        qualifierKey = [bits objectAtIndex:i];

        // wtf is this?
        if (i >= ([bits count] - 1)) { break; }

        // otherwise, look up the relationship
        var relationship = [cecd relationshipWithName:qualifierKey];

        // if there's no such relationship, it might be a derived data source
        // so check for that

        if (!relationship) {
            //WM::Log::debug("Grabbing derived source with name $qualifierKey");
            relationship = [sqlExpression derivedDataSourceWithName:qualifierKey];
        }

        if (!relationship) {
            relationship = [sqlExpression dynamicRelationshipWithName:qualifierKey];
            //WM::Log::error("Using dynamic relationship");
        }

        if (!relationship) {
            [WMLog error:"Relationship " + qualifierKey + " not found on entity " + [cecd name]];
            return {};
        }

        var tecd = [relationship targetEntityClassDescription:model];

        if (![WMLog assert:tecd message:"Target entity class " + [relationship targetEntity] + " exists"]) {
            return {};
        }

        //if ([tecd isAggregateEntity]) {
            // We just bail on it if it's aggregate
            // TODO see if there's a way to insert an aggregate qualifier into the key path
            //
    //        return {};
    //    }
        // follow it
        [sqlExpression addTraversedRelationship:qualifierKey onEntity:cecd];
        cecd = tecd;
    }
    return {
        TARGET_ENTITY_CLASS_DESCRIPTION: cecd,
        TARGET_ATTRIBUTE: qualifierKey,
    };
}

- (CPString) description {
    return "<" + [self class] + ": " + [self name] + ">";
}

@end
