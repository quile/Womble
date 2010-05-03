@import "Model/_Trunk.j"
@import <Foundation/CPKeyValueCoding.j>

@implementation IFTestTrunk : _IFTestTrunkModel
{
}

/*
sub Model {
    belongsTo("Root"),
    hasMany("Branch")->called("branches"),
}
*/

+ _test_dropTableCommand {
    return [
        "DROP TABLE IF EXISTS `TRUNK`;"
    ];
}

+ _test_createTableCommand {
    return [
        "CREATE TABLE `TRUNK` ("
        + " ID INTEGER PRIMARY KEY NOT NULL,"
        + " CREATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
        + " MODIFICATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
        + " ROOT_ID INTEGER NOT NULL DEFAULT 0,"
        + " THICKNESS INTEGER NOT NULL DEFAULT 0"
        + ")",
    ]
}

@end
