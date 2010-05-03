/* --------------------------------------------------------------------
 * IF - Web Framework and ORM heavily influenced by WebObjects & EOF
 * (C) kd 2010
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "../Dictionary.j";
@import "../DB.j";

@implementation IFDBMySQL : IFDictionary
{
}

- initWithHandle:(id)h {
    [super init];
    wrappedHandle = h;
    lastInsertId = nil;
    return self;
}

- do:(id)sql {
    return [dbh do:sql];
}

- descriptionOfTable:(id)tableName {
    var sql = "SHOW COLUMNS FROM " + tableName;
    return [IFDB rawRowsForSQL:sql];
}

- lastInsertId {
    return [wrappedHandle lastInsertId];
}

- countUsingSql:(id)sql {
    return [IFDB rawRowsForSQL:sql];
}

- nextNumberForSequence:(id)sequenceName {
    var nextId;
    if (!wrappedHandle) { return null; }

    var sequenceTable = [IFApplication systemConfigurationValueForKey:"SEQUENCE_TABLE"];
    var sth = [wrappedHandle prepare:"LOCK TABLES " + sequenceTable + " WRITE"];
    if ([sth execute]) {
        var fsth = [wrappedHandle prepare:"SELECT NEXT_ID FROM " + sequenceTable + " WHERE NAME = ?"];
        if ([fsth executeWithBindValues:[sequenceName]]) {
            var nextId = [[sth nextResultAsArray] objectAtIndex:0];
            [fsth finish];
            if (!nextId) {
                [wrappedHandle do:[IFSQLStatement newWithSQL:"INSERT INTO " + sequenceTable + " (NAME, NEXT_ID) VALUES (?, ?)" andBindValues:[[IFArray alloc] initWithObjects:sequenceName, 1]]];
                nextId = 1;
            }

            [wrappedHandle do:[IFSQLStatement newWithSQL:"UPDATE " + sequenceTable + " SET NEXT_ID=NEXT_ID+1 WHERE NAME=?" andBindValues:[[IFArray alloc] initWithObjects:sequenceName]]];
            [wrappedHandle do:"UNLOCK TABLES"];
        }
        [sth finish];
    }
    return nextId;
}

@end
