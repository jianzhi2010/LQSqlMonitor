//
//  LQSqlMonitor.m
//  LQSqlMonitorDemo
//
//  Created by liang on 2017/6/30.
//  Copyright © 2017年 liang. All rights reserved.
//

#import "LQSqlMonitor.h"
#import "fishhook.h"
#import <sqlite3.h>
#import <QuartzCore/QuartzCore.h>

static NSString *const kSqliteKeyPrepareStartTime = @"kSqliteKeyPrepareStartTime";
static NSString *const kSqliteKeyPrepareSql = @"kSqliteKeyPrepareSql";

static CFTimeInterval sqlTimeThreshold = 100; //ms
static NSCache *sqlCache;

SQLITE_API int SQLITE_STDCALL (*original_sqlite3_prepare_v2)(sqlite3 *db,
                                                             const char *zSql,
                                                             int nByte,
                                                             sqlite3_stmt **ppStmt,
                                                             const char **pzTail );

SQLITE_API int SQLITE_STDCALL new_sqlite3_prepare_v2(sqlite3 *db,
                                                     const char *zSql,
                                                     int nByte,
                                                     sqlite3_stmt **ppStmt,
                                                     const char **pzTail)
{
    CFTimeInterval startTime = CACurrentMediaTime();
    
    int result = original_sqlite3_prepare_v2(db, zSql, nByte, ppStmt, pzTail);
    
    NSDictionary *sqlInfo = @{kSqliteKeyPrepareSql : [NSString stringWithUTF8String:zSql], kSqliteKeyPrepareStartTime : @(startTime)};
    
    char stmtAddress[128];
    sprintf(stmtAddress, "%p", *ppStmt);
    
    [sqlCache setObject:sqlInfo forKey:[NSString stringWithUTF8String:stmtAddress]];
    
    return result;
}


SQLITE_API int SQLITE_STDCALL (*original_sqlite3_finalize)(sqlite3_stmt *pStmt);

SQLITE_API int SQLITE_STDCALL new_sqlite3_finalize(sqlite3_stmt *pStmt) {

    int result = original_sqlite3_finalize(pStmt);
    
    CFTimeInterval endTime = CACurrentMediaTime();
    
    char stmtAddress[128];
    sprintf(stmtAddress, "%p", pStmt);

    NSDictionary *sqlInfo = [sqlCache objectForKey:[NSString stringWithUTF8String:stmtAddress]];
    
    CFTimeInterval startTime = [sqlInfo[kSqliteKeyPrepareStartTime] doubleValue];
    CFTimeInterval duration = (endTime - startTime) * 1000.0; //ms
    
    if (duration > sqlTimeThreshold) {
        NSLog(@"%@ | executeTime:%.2fms", sqlInfo[kSqliteKeyPrepareSql], duration);
    }
    
    [sqlCache removeObjectForKey:[NSString stringWithUTF8String:stmtAddress]];

    return result;
}


@implementation LQSqlMonitor

#ifdef DEBUG

+ (void)load {
    
    struct rebinding sqlite_prepare_rebinding = { "sqlite3_prepare_v2", new_sqlite3_prepare_v2, (void *)&original_sqlite3_prepare_v2 };
    struct rebinding sqlite_finalize_rebinding = { "sqlite3_finalize", new_sqlite3_finalize, (void *)&original_sqlite3_finalize };
    
    rebind_symbols((struct rebinding[2]){sqlite_prepare_rebinding, sqlite_finalize_rebinding}, 2);
    
    
    sqlCache = [[NSCache alloc] init];
}

#endif

+ (void)setSqlTimeThreshold:(CFTimeInterval)timeThreshold {
    sqlTimeThreshold = timeThreshold;
}

@end
