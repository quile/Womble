@import "Model/_Ground.j"
@import <Foundation/CPKeyValueCoding.j>

@implementation WMTestGround : _WMTestGroundModel
{
}

// this is just for testing purposes
+ _test_dropTableCommand {
    return "DROP TABLE IF EXISTS `GROUND`";
}

+ _test_createTableCommand {
    return "CREATE TABLE `GROUND` ("
         + "ID INTEGER PRIMARY KEY NOT NULL,"
         + "CREATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
         + "MODIFICATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
         + "COLOUR CHAR(255) NOT NULL DEFAULT ''"
         + ")";
}


@end
