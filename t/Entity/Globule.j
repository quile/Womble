@import "Model/_Globule.j"
@import <Foundation/CPKeyValueCoding.j>

@implementation IFTestGlobule : _IFTestGlobuleModel
{
}

/*
sub Model {
    hasManyToMany("Branch")
        ->called("branches")
        ->joinedThrough('BRANCH_X_GLOBULE')
        ->deleteBy('NULLIFY')
        ->reciprocalRelationshipName("globules")
}
*/

+ _test_dropTableCommand {
    return [
        "DROP TABLE IF EXISTS `GLOBULE`",
        "DROP TABLE IF EXISTS `BRANCH_X_GLOBULE`",
    ];
}

+ _test_createTableCommand {
    return [
        "CREATE TABLE `GLOBULE` ("
            + " ID INTEGER PRIMARY KEY NOT NULL,"
            + " CREATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
            + " MODIFICATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
            + " NAME VARCHAR(64) NOT NULL DEFAULT ''"
            + ")",
        "CREATE TABLE `BRANCH_X_GLOBULE` ("
            + " ID INTEGER PRIMARY KEY NOT NULL,"
            + " CREATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
            + " MODIFICATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
            + " BRANCH_ID INTEGER NOT NULL DEFAULT 0,"
            + " GLOBULE_ID INTEGER NOT NULL DEFAULT 0,"
            + " FOO VARCHAR(32),"
            + " BAR VARCHAR(32)"
            + ")"
    ];
}

@end
