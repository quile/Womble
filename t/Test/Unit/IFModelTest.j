@import <OJUnit/OJTestCase.j>
@import "../../Application.j"
@import <IF/Model.j>

// fire up the app
[IFLog setLogMask:0x0000];
application = [IFTestApplication applicationInstanceWithName:"IFTest"];

@implementation _TestIFModel : IFModel

- populateModel {
    // i have to implement this or it will yack.
}

@end


@implementation IFModelTest : OJTestCase
{
    IFModel model;
}

- (void) setUp {
    var modelData = [IFModelTest MODEL_DATA];
    model = [[_TestIFModel alloc] initWithModelData:modelData];
}

- (void) testExistence {
    [self assertTrue:model message:"Model exists"];
}

- (void) testEntityClassDescription {
    var ecd = [model entityClassDescriptionForEntityNamed:"Bong"];
    [self assertTrue:ecd message:"Grabbed entity class description by name"];
    var entityNames = [model allEntityClassKeys];
    [IFLog dump:entityNames];
    [self assert:entityNames.length equals:1 message:"Correct number of entity class descriptions in model"];
    var ecd = [model entityClassDescriptionForTable:"BONG"];
    [self assertTrue:ecd message:"Grabbed entity class description by table"];
}

// test application - this should be someone else

- (void) testApplicationGoop {
    // TODO come up with test values instead of these real ones.
    [self assert:[application configurationValueForKey:"SYSTEM_CONFIGURATION_VALUE"] equals:"Foo"];
    [self assert:[application configurationValueForKey:"APP_CONFIGURATION_VALUE"] equals:"Bar"];
    [self assert:[application configurationValueForKey:"MASKED_CONFIGURATION_VALUE"] equals:"Baz"];
}

- (void) testDatabaseConfig {
    var dbc = [IFDB databaseInformation];
    [self assertNotNull:dbc];
    [self assertNotNull:dbc.DATA_SOURCES];
}

// test data
+ MODEL_DATA {
    return {
        'NAMESPACE': {
            'ENTITY': 'TestIFEntity',
        },
        'ENTITIES': {
            'Bong': {
                'NAME': 'Bong',
                'PRIMARY_KEY': 'ID',
                'TABLE': 'BONG',
                'ATTRIBUTES': {
                    'ID': {
                        'KEY': 'YES',
                        'SIZE': '11',
                        'NULL': 'NO',
                        'DEFAULT': '0',
                        'TYPE': 'int',
                        'COLUMN_NAME': 'ID',
                        'ATTRIBUTE_NAME': 'id',
                        'EXTRA': '0',
                        'VALUES': []
                    },
                    'CREATION_DATE': {
                        'KEY': null,
                        'SIZE': null,
                        'NULL': null,
                        'DEFAULT': '\'0000-00-00 00:00:00\'',
                        'TYPE': 'DATETIME',
                        'COLUMN_NAME': 'CREATION_DATE',
                        'ATTRIBUTE_NAME': 'creationDate',
                        'EXTRA': '\'0000-00-00 00:00:00\'',
                        'VALUES': []
                    },
                    'MODIFICATION_DATE': {
                        'KEY': null,
                        'SIZE': null,
                        'NULL': null,
                        'DEFAULT': '\'0000-00-00 00:00:00\'',
                        'TYPE': 'DATETIME',
                        'COLUMN_NAME': 'MODIFICATION_DATE',
                        'ATTRIBUTE_NAME': 'modificationDate',
                        'EXTRA': '\'0000-00-00 00:00:00\'',
                        'VALUES': []
                    },
                    'COLOUR': {
                        'KEY': null,
                        'SIZE': 32,
                        'NULL': null,
                        'DEFAULT': '\'Brown\'',
                        'TYPE': 'VARCHAR',
                        'COLUMN_NAME': 'COLOUR',
                        'ATTRIBUTE_NAME': 'colour',
                        'EXTRA': '\'Brown\'',
                        'VALUES': []
                    },
                },
                RELATIONSHIPS: {

                },
            },
        },
    };
}
