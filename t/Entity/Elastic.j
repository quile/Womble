@import "Model/_Elastic.j"
@import <Foundation/CPKeyValueCoding.j>

@implementation IFTestElastic : _IFTestElasticModel
{
}

/*
sub Model {
}
*/

+ _test_dropTableCommand {
    return [
        "DROP TABLE IF EXISTS `ELASTIC`"
    ];
}

+ _test_createTableCommand {
    return [
        "CREATE TABLE `ELASTIC` ("
      + "ID INTEGER PRIMARY KEY NOT NULL,"
      + "CREATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
      + "MODIFICATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
      + "TARGET_ID INTEGER NOT NULL DEFAULT 0,"
      + "SOURCE_ID INTEGER NOT NULL DEFAULT 0,"
      + "TARGET_TYPE STRING NOT NULL DEFAULT '',"
      + "SOURCE_TYPE STRING NOT NULL DEFAULT '',"
      + "PLING VARCHAR(32)"
      + ")",
    ];
}

@end
