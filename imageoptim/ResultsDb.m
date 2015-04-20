
#import "ResultsDb.h"
#import "log.h"
#include <sqlite3.h>

@implementation ResultsDb {
    sqlite3 *db;
    dispatch_queue_t sqlitequeue;
}

typedef BOOL (^rowcallback)(int numColumns, char **values, char **columnNames);

- (instancetype)init
{
    if ((self = [super init])) {
        NSURL *cachesPath = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
        cachesPath = [cachesPath URLByAppendingPathComponent:@"ImageOptimResults.db"];
        IODebug(@"Results cache is in %@", cachesPath.path);
        if (SQLITE_OK != sqlite3_open([cachesPath.path fileSystemRepresentation], &db)) {
            IOWarn(@"Failed to open db: %s", sqlite3_errmsg(db));
            sqlite3_close(db);
            db = NULL;
            return nil;
        }
        sqlitequeue = dispatch_queue_create("imageoptim sqlite", DISPATCH_QUEUE_SERIAL);
        dispatch_async(sqlitequeue, ^(){
            char *err;
            if (SQLITE_OK != sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS results(inputs_hashsh BLOB(16) NOT NULL PRIMARY KEY, size INT NOT NULL, status INT NOT NULL DEFAULT 0);"
                                              "CREATE INDEX IF NOT EXISTS results_size ON results(size)", NULL, NULL, &err)) {
                IOWarn(@"Failed to create tables: %s", err);
                sqlite3_free(err);
            }
        });
    }
    return self;
}

-(void)dealloc {
    if (db) {
        sqlite3 *dbtmp = db;
        dispatch_sync(sqlitequeue, ^(){
            sqlite3_close(dbtmp);
        });
    }
    sqlitequeue = nil;
}

-(void)setUnoptimizableFileHash:(uint32_t[static 4])hash size:(NSUInteger)byteSizeOnDisk {
    assert(hash[0]||hash[1]||hash[2]||hash[3]);

    [self runQuery:[NSString stringWithFormat:@"INSERT INTO results(inputs_hashsh, size, status) VALUES(x'%08x%08x%08x%08x', %lu, 1)", hash[0],hash[1],hash[2],hash[3], byteSizeOnDisk] withBlock:nil];
}

-(BOOL)getResultWithHash:(uint32_t[static 4])hash {
    assert(hash[0]||hash[1]||hash[2]||hash[3]);

    BOOL __block found = NO;
    [self runQuery:[NSString stringWithFormat:@"SELECT 1 FROM results WHERE inputs_hashsh = x'%08x%08x%08x%08x' LIMIT 1", hash[0],hash[1],hash[2],hash[3]] withBlock:^BOOL(int c, char**a, char**b){
        found = YES;
        return YES;
    }];
    return found;
}

-(BOOL)hasResultWithFileSize:(NSUInteger)size {
    BOOL __block found = NO;
    [self runQuery:[NSString stringWithFormat:@"SELECT 1 FROM results WHERE size = %lu LIMIT 1", (long)size] withBlock:^BOOL(int c, char**a, char**b){
        found = YES;
        return YES;
    }];
    return found;
}

static int invokeBlockCallback(void *blockp, int numColumns, char **values, char **columnNames){
    rowcallback b = (__bridge rowcallback)blockp;
    return !b(numColumns, values, columnNames);
}

-(BOOL)runQuery:(NSString*)query withBlock:(rowcallback)block {
    BOOL __block res = YES;
    dispatch_sync(sqlitequeue, ^(){
        char *err;
        if (SQLITE_OK != sqlite3_exec(db, [query UTF8String], block ? invokeBlockCallback : NULL, (__bridge void*)block, &err)) {
            IOWarn(@"Query failed: %s in %@", err, query);
            sqlite3_free(err);
            res = NO;
        }
    });
    return res;
}

@end
