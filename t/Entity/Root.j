@import "Model/_Root.j"
@import <Foundation/CPKeyValueCoding.j>

@implementation IFTestRoot : _IFTestRootModel
{
}

/*
sub Model {
    hasOne("Trunk"),
    belongsTo("Ground"),
}
*/

+ _test_dropTableCommand {
    return [
        "DROP TABLE IF EXISTS `ROOT`;",
    ];
}

+ _test_createTableCommand {
    return [
        "CREATE TABLE `ROOT` ("
        + " ID INTEGER PRIMARY KEY NOT NULL,"
        + " CREATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
        + " MODIFICATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
        + " GROUND_ID INTEGER NOT NULL DEFAULT 0,"
        + " TITLE CHAR(255) NOT NULL DEFAULT ''"
        + ")",
    ]
}

@end
