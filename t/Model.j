@import <WM/WMModel.j>
@import <WM/WMDB.j>

@implementation WMTestModel : WMModel

- populateModel {
    // i have to implement this or it will yack.
}

- (void)createTables {
	for (entityClass in model.ENTITIES) {
		[WMLog debug:"Creating table for " + entityClass];
        var cls = objj_getClass(entityClass);
        var ecd = model.ENTITIES[entityClass];
        var sqls = [WMArray arrayFromObject:[cls _test_createTableCommand]];
        for (var i=0; i < [sqls count]; i++) {
            var sql = sqls[i];
            if (sql) {
                [WMDB executeArbitrarySQL:sql];
            }
        }
	}
}

- (void)dropTables {
	for (entityClass in model.ENTITIES) {
		[WMLog debug:"Dropping table for " + entityClass];
        var cls = objj_getClass(entityClass);
        var ecd = model.ENTITIES[entityClass];
        var sqls = [WMArray arrayFromObject:[cls _test_dropTableCommand]];
        for (var i=0; i < [sqls count]; i++) {
            var sql = sqls[i];
            if (sql) {
                [WMDB executeArbitrarySQL:sql];
            }
        }
	}
}

@end
