//
//  MCupgradeDBManager.m
//  DBkit
//
//  Created by wangdaoqinqiyi on 15/12/9.
//  Copyright © 2015年 JK. All rights reserved.
//

#import "MCupgradeDBManager.h"
#import "SqliteHelper.h"
@implementation MCupgradeDBManager
+(NSString*)localDBConfigPath
{
    NSString* document=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString* local=[document stringByAppendingPathComponent:@"upgradedb.plist"];
    return local;
}
+(NSString*)newDBConfigPath
{
    return  [[NSBundle mainBundle]pathForResource:@"upgradedb" ofType:@"plist"];
}



+(void)checkDb
{
    NSString* local=[MCupgradeDBManager localDBConfigPath];
    NSString* new=[MCupgradeDBManager newDBConfigPath];
    NSDictionary *dicNew=[NSDictionary dictionaryWithContentsOfFile:new];
    
    NSFileManager* fm=[NSFileManager defaultManager];
    if ([fm fileExistsAtPath:local])
    {
         NSDictionary *dicOld=[NSDictionary dictionaryWithContentsOfFile:local];
        NSString* nv=[dicNew objectForKey:@"version"];
        NSString* ov=[dicOld objectForKey:@"version"];
        if ([nv compare:ov]!=NSOrderedSame)
        {//版本不同则更新数据库
            @try {
                [[SqliteHelper shareInstance] BeginTransaction];
                //取出all新数据列表
                NSDictionary* tables=[dicNew objectForKey:@"tables"];
                //取出all老数据列表
                NSDictionary* localtables=[dicOld objectForKey:@"tables"];
                NSArray *tableNames=[tables allKeys];
                for (int i=0; i<tableNames.count; i++)
                {
                    //获取表名
                    NSString*tableName=tableNames[i];
                    //取出新表
                    NSDictionary*table=[tables objectForKey:tableName];
                    //取出老表
                    NSDictionary*localtable=[localtables objectForKey:tableName];
                    if(!localtable)
                    {//没有老表，插入新表
                        [MCupgradeDBManager insertTable:table tableName:tableName];
                    }
                    else
                    {//存在老表，轮询列
                        NSDictionary *cols=[table objectForKey:@"colunms"];
                        NSDictionary *localcols=[localtable objectForKey:@"colunms"];
                        NSArray *colnames=[cols allKeys];
                        for (int j=0; j<colnames.count; j++)
                        {
                            NSString *colname=colnames[j];
                            NSDictionary *col=[cols objectForKey:colname];
                            NSString *type=[col objectForKey:@"type"];
                            NSDictionary *localcol=[localcols objectForKey:colname];
                            if(!localcol)
                            {//本地这列，添加
                                NSString *sql=[NSString stringWithFormat:@"alter table %@ add %@ %@",tableName,colname,type];
                                [[SqliteHelper shareInstance] ExecSQL:sql throwEx:YES];
                            }
                        }
                    }
                }
                [fm removeItemAtPath:local error:nil];
                [fm copyItemAtPath:new toPath:local error:nil];
                
                [[SqliteHelper shareInstance] CommitTransaction];
            }
            @catch (NSException *exception) {
                [[SqliteHelper shareInstance] RollbackTransaction];
            }
            @finally {
                [[SqliteHelper shareInstance] CloseSqlite];
            }
        }
        
        
    }
    else
    {
       [[SqliteHelper shareInstance] BeginTransaction];
        @try {
            NSDictionary *tables=[dicNew objectForKey:@"tables"];
            NSArray *tablenames=[tables allKeys];
            for (int i=0; i<tablenames.count;i++) {
                NSDictionary *table=[tables objectForKey:tablenames[i]];
                [MCupgradeDBManager insertTable:table tableName:tablenames[i]];
            }
            [fm copyItemAtPath:new  toPath:local error:nil];
             [[SqliteHelper shareInstance] CommitTransaction];
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception reason]);
            [[SqliteHelper shareInstance] RollbackTransaction];
        }
        @finally {
            [[SqliteHelper shareInstance] CloseSqlite];
        }
        
 
    }
    
}



+(void)insertTable:(NSDictionary*)table tableName:(NSString*)tablename
{
    NSString* pk=[table objectForKey:@"pk"];
    NSDictionary *cols=[table objectForKey:@"colunms"];
    NSString* sql=[NSString stringWithFormat:@"create table %@ (",tablename];
    NSArray *colnames=[cols allKeys];
    colnames=[colnames sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDictionary *dic1=[cols objectForKey:obj1];
        NSDictionary *dic2=[cols objectForKey:obj2];
        return [[dic1 objectForKey:@"colid"] compare:[dic2 objectForKey:@"colid"]];
    }];
    for (int j=0; j<colnames.count; j++) {
        NSString* colname=colnames[j];
        NSDictionary *dic=[cols objectForKey:colname];
        NSString* type=[dic objectForKey:@"type"];
        sql=[sql stringByAppendingFormat:@"%@ %@",colname,type];
        if([colname compare:pk]==NSOrderedSame){
            sql=[sql stringByAppendingFormat:@" PRIMARY KEY"];
        }
        if(j<colnames.count-1)
            sql=[sql stringByAppendingFormat:@" ,"];
        
    }
    sql=[sql stringByAppendingFormat:@" )"];
    [[SqliteHelper shareInstance] ExecSQL:sql throwEx:YES];
}


@end
