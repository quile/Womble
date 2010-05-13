@import "Model/_Zab.j"
@import <Foundation/CPKeyValueCoding.j>

@implementation WMTestZab : _WMTestZabModel
{
}

/*
sub Model {}
*/

+ _test_dropTableCommand {
    return [
        "DROP TABLE IF EXISTS `ZAB`;"
    ];
}

+ _test_createTableCommand {
    return [
        "CREATE TABLE `ZAB` ("
        + " ID INTEGER PRIMARY KEY NOT NULL,"
        + " CREATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
        + " MODIFICATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
        + " TITLE CHAR(32) NOT NULL DEFAULT ''"
        + ")",
    ]
}

@end
