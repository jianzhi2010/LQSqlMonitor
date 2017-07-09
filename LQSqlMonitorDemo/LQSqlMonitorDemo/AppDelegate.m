//
//  AppDelegate.m
//  LQSqlMonitorDemo
//
//  Created by liang on 2017/7/9.
//  Copyright © 2017年 liang. All rights reserved.
//

#import "AppDelegate.h"
#import <sqlite3.h>
#import "LQSqlMonitor.h"

static NSString *const CREATE_USER_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS t_user ( \
id INTEGER NOT NULL, \
name TEXT NOT NULL, \
nickName TEXT, \
avatarUrl TEXT, \
phone TEXT, \
createdTime TEXT,\
PRIMARY KEY(id)) \
";

@interface AppDelegate ()

@property (nonatomic) sqlite3 *database;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    
    //Print each SQLite query
    [LQSqlMonitor setSqlTimeThreshold:0.0];
    
    [self testQuery];
    
    return YES;
}


# pragma mark - Test

- (void)testQuery {
    [self prepareTestData];
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM t_user WHERE createdTime <= '%@' ORDER BY name DESC", [NSDate date]];
    [self executeQuery:sql];
}

- (void)prepareTestData {
    
    [self openDatabase:@"test.db"];
    
    [self executeUpdate:CREATE_USER_TABLE_SQL];
    
    for (int i = 0; i < 100; i++) {
        NSString *addUserSql = [NSString stringWithFormat:@"INSERT INTO t_user (name, nickName, avatarUrl, phone, createdTime) VALUES('%@','%@','%@','%@', '%@')", [NSString stringWithFormat:@"lq%d", i], @"nick", @"https://github.com/jianzhi2010/LQSqlMonitor", @"8613722223333", [NSDate date]];
        [self executeUpdate:addUserSql];
    }
}

# pragma mark - SQLite

- (void)openDatabase:(NSString *)databaseName {
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    NSString *filePath = [directory stringByAppendingPathComponent:databaseName];
    
    assert(sqlite3_threadsafe());
    
    if (SQLITE_OK == sqlite3_open([filePath UTF8String], &_database)) {
        NSLog(@"Open database succeed");
    } else {
        NSAssert(1, @"Open database failed!");
    }
}

- (void)executeUpdate:(NSString *)sql {
    if (sql.length == 0) {
        return;
    }
    
    char *error;
    if (SQLITE_OK != sqlite3_exec(_database, sql.UTF8String, NULL, NULL, &error)) {
        NSLog(@"Execute sql error：%s",error);
    }
}

- (NSArray *)executeQuery:(NSString *)sql {
    if (sql.length == 0) {
        return nil;
    }
    
    NSMutableArray *rows= [NSMutableArray array];
    sqlite3_stmt *stmt;
    
    if (SQLITE_OK == sqlite3_prepare_v2(_database, sql.UTF8String, -1, &stmt, NULL)) {
        
        while (SQLITE_ROW == sqlite3_step(stmt)) {
            
            int columnCount= sqlite3_column_count(stmt);
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            for (int i=0; i < columnCount; i++) {
                const char *name= sqlite3_column_name(stmt, i);
                const unsigned char *value= sqlite3_column_text(stmt, i);
                dic[[NSString stringWithUTF8String:name]] = [NSString stringWithUTF8String:(const char *)value];
            }
            
            [rows addObject:dic];
        }
    } else {
        NSLog(@"Query error");
    }
    
    sqlite3_finalize(stmt);
    
    return rows;
}

@end
