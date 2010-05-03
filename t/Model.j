@import <IF/Model.j>
@import <IF/DB.j>

@implementation IFTestModel : IFModel

- populateModel {
    // i have to implement this or it will yack.
}

- (void)createTables {
	for (entityClass in model.ENTITIES) {
		[IFLog debug:"Creating table for " + entityClass];
        var cls = objj_getClass(entityClass);
        var ecd = model.ENTITIES[entityClass];
        var sqls = [IFArray arrayFromObject:[cls _test_createTableCommand]];
        for (var i=0; i < [sqls count]; i++) {
            var sql = sqls[i];
            if (sql) {
                [IFDB executeArbitrarySQL:sql];
            }
        }
	}
}

- (void)dropTables {
	for (entityClass in model.ENTITIES) {
		[IFLog debug:"Dropping table for " + entityClass];
        var cls = objj_getClass(entityClass);
        var ecd = model.ENTITIES[entityClass];
        var sqls = [IFArray arrayFromObject:[cls _test_dropTableCommand]];
        for (var i=0; i < [sqls count]; i++) {
            var sql = sqls[i];
            if (sql) {
                [IFDB executeArbitrarySQL:sql];
            }
        }
	}
}

@end
