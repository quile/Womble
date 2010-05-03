@import "Model/_Branch.j"
@import <Foundation/CPKeyValueCoding.j>

@implementation IFTestBranch : _IFTestBranchModel
{
}

/*sub Model {
    belongsTo("Trunk"),
    hasManyToMany("Globule")
        ->called("globules")
        ->joinedThrough('BRANCH_X_GLOBULE')
        ->deleteBy('NULLIFY')
        ->reciprocalRelationshipName("branches")
}
*/

// this is just for testing purposes
+ _test_dropTableCommand {
    return "DROP TABLE IF EXISTS `BRANCH`";
}

+ _test_createTableCommand {
    return "CREATE TABLE `BRANCH` ("
         + "ID INTEGER PRIMARY KEY NOT NULL,"
         + "CREATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
         + "MODIFICATION_DATE DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',"
         + "LENGTH INTEGER NOT NULL DEFAULT 0,"
         + "TRUNK_ID INTEGER NOT NULL DEFAULT 0,"
         + "LEAF_COUNT INTEGER NOT NULL DEFAULT 0,"
         + "ZAB_TYPE VARCHAR(16),"
         + "ZAB_ID INTEGER NOT NULL DEFAULT 0"
         + ")";
}

@end
