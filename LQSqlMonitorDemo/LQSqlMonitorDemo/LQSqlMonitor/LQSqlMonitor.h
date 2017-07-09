//
//  LQSqlMonitor.h
//  LQSqlMonitorDemo
//
//  Created by liang on 2017/6/30.
//  Copyright © 2017年 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQSqlMonitor : NSObject

/*
 * The execution time of SQLite query above your time threshold 
 * will print out the sql and the execution time.
 *
 * The default timeThreshold is 10ms.
 */
+ (void)setSqlTimeThreshold:(CFTimeInterval)timeThreshold;

@end
