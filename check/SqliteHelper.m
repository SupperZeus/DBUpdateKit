

#import "SqliteHelper.h"
#import "MCupgradeDBManager.h"
#import "ToolMethod.h"
#define  DB_NAME @"app"
#define DATEFORMATTER @"yyyy/MM/dd HH:mm:ss"

static SqliteHelper *instance=nil;
@implementation SqliteHelper
@synthesize delegate;
+(SqliteHelper*)shareInstance
{
    if (instance==nil)
    {
        instance=[[SqliteHelper alloc] initWithDataPath:[SqliteHelper pathOfDB]];
        [instance OpenSqlite];
    }
    return instance;
}
+(NSString*) pathOfDB
{
    NSString* document=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString* dbPath=[[document stringByAppendingPathComponent:DB_NAME] stringByAppendingString:@".sqlite"];
    NSLog(@"数据库地址为:%@",dbPath);
    return dbPath;
}

-(id)initWithDataPath:(NSString*)dataPath{
    if(self=[super init]){
        filePath=dataPath;
    }
    return self;
}
//打开数据库
-(int)OpenSqlite{
    int result= sqlite3_open([filePath UTF8String], &sqlite);
    if(result!=SQLITE_OK)
    {
        NSLog(@"打开数据库失败");
        NSException *ex=[NSException exceptionWithName:@"sqlite操作异常" reason:@"打开数据库失败" userInfo:nil];
        @throw ex;
        
    }
    return result;
}
-(int)BeginTransaction{
    char *error;
    int result=  sqlite3_exec( sqlite, "begin transaction", 0, 0, &error );
    if(result!=SQLITE_OK)
    {
        NSLog(@"开始事务失败");
        NSException *ex=[NSException exceptionWithName:@"sqlite操作异常" reason:@"开始事务失败" userInfo:nil];
        @throw ex;
        
    }
    return result;
}
-(int)CommitTransaction{
    char *error;
    int result=  sqlite3_exec( sqlite, "commit transaction", 0, 0, &error );
    if(result!=SQLITE_OK)
    {
        NSLog(@"提交事务失败");
        NSException *ex=[NSException exceptionWithName:@"sqlite操作异常" reason:@"提交事务失败" userInfo:nil];
        @throw ex;
    }
    return result;
}
-(int)RollbackTransaction{
    char *error;
    int result=  sqlite3_exec( sqlite, "rollback transaction", 0, 0, &error );
    if(result!=SQLITE_OK)
    {
        NSLog(@"回滚事务失败");
        NSException *ex=[NSException exceptionWithName:@"sqlite操作异常" reason:@"回滚事务失败" userInfo:nil];
        @throw ex;
    }
    return result;
}
//创建表
-(int)ExecSQL:(NSString*) sql throwEx:(BOOL) throwEx;{
    
    
    //打开数据库
    
    
    char *error;
    int result= sqlite3_exec(sqlite, [sql UTF8String], NULL,NULL, &error);
    if(result!=SQLITE_OK)
    {
        NSLog(@"执行%@失败：%s",sql,error);
        if(throwEx)
        {
            NSException *ex=[NSException exceptionWithName:@"sqlite操作异常" reason:[NSString stringWithFormat:@"执行SQL语句失败,sql:%@",sql] userInfo:nil];
            
            
            @throw ex;
        }
    }
    
    
    return  result;
    
}
//更新删除数据
-(int)UpdateData:(NSString*) sql forTag:(NSInteger) tag throwEx:(BOOL) throwEx{
    sqlite3_stmt *stmt;
    int result=sqlite3_prepare_v2(sqlite, [sql UTF8String], -1,&stmt, NULL);
    result=[self configurationParameterForStmt:stmt forTag:tag];
    
    sqlite3_finalize(stmt);
    if(result!=SQLITE_DONE){
        NSLog(@"更新数据失败%@",sql);
        
        
        if(throwEx)
        {
            NSException *ex=[NSException exceptionWithName:@"sqlite操作异常" reason:[NSString stringWithFormat:@"更新数据失败,sql:%@",sql] userInfo:nil];
            @throw ex;
            
        }
        
    }
    
    return result;
}

//向表中插入数据,count为需要插入的行数
-(void)InsertData:(NSString*) sql forTag:(NSInteger) tag count:(NSInteger)count throwEx:(BOOL) throwEx{
    
    if([self.delegate respondsToSelector:@selector(configurationParameterForStmt:forTag:forRow:)]){
        for(NSInteger i=0;i<count;i++){
            sqlite3_stmt *stmt;
            sqlite3_prepare_v2(sqlite, [sql UTF8String], -1,&stmt, NULL);
            [self.delegate configurationParameterForStmt:stmt forTag:tag forRow:i];
            int result= sqlite3_step(stmt);
            sqlite3_finalize(stmt);
            if(result!=SQLITE_DONE){
                NSLog(@"第%ld行插入失败",i+1);
                if(throwEx)
                {
                    NSException *ex=[NSException exceptionWithName:@"sqlite操作异常" reason:[NSString stringWithFormat:@"插入数据失败,sql:%@",sql] userInfo:nil];
                    @throw ex;
                    
                }
            }
        }
    }else{
        NSLog(@"没有设置代理");
    }
}
-(void)CloseSqlite{
    sqlite3_close(sqlite);
}
-(int)configurationParameterForStmt:(sqlite3_stmt*) stmt forTag:(NSInteger) tag{
    
    if([self.delegate respondsToSelector:@selector(configurationParameterForStmt:forTag:)]){
        [self.delegate configurationParameterForStmt:stmt forTag:tag];
        return sqlite3_step(stmt);
    }
    else
    {
        NSLog(@"没有设置代理");
        return -1;
    }
}
//查询数据
-(NSMutableArray*)selectTable:(NSString*) sql forTag:(NSInteger) tag{
    sqlite3_stmt *stmt;
    sqlite3_prepare_v2(sqlite, [sql UTF8String], -1,&stmt, NULL);
    
    NSMutableArray *arr=[[NSMutableArray alloc]init];
    int result= [self configurationParameterForStmt:stmt forTag:tag];
    if([self.delegate respondsToSelector:@selector(ManageValueForSelect:forTag:)]){
        while (result==SQLITE_ROW) {
            id object=[self.delegate ManageValueForSelect:stmt forTag:tag];
            [arr addObject:object];
            result= sqlite3_step(stmt);
        }
    }
    else
    {
        NSLog(@"没有设置代理");
    }
    sqlite3_finalize(stmt);
    return arr;
}



-(id)sqlite3_column_Value:(sqlite3_stmt*)stmt type:(NSString*)type column:(NSInteger) column{
    @try {
        
        if([type compare:@"bigint"]==NSOrderedSame||[type compare:@"int"]==NSOrderedSame||[type compare:@"smallint"]==NSOrderedSame)
        {
            return [NSNumber numberWithInteger:[self sqlite3_column_Int:stmt column:column]];
        }
        else if ([type compare:@"bit"]==NSOrderedSame)
        {
            return [NSNumber numberWithBool:[self sqlite3_column_Bool:stmt column:column]];
        }
        else if ([type compare:@"char"]==NSOrderedSame||[type compare:@"nchar"]==NSOrderedSame||[type compare:@"ntext"]==NSOrderedSame||[type compare:@"text"]==NSOrderedSame||[type compare:@"uniqueidentifier"]==NSOrderedSame||[type compare:@"nvarchar"]==NSOrderedSame||[type compare:@"varchar"]==NSOrderedSame||[type compare:@"xml"]==NSOrderedSame)
        {
            return [self sqlite3_column_String:stmt column:column];
        }
        else if ([type compare:@"datetime"]==NSOrderedSame||[type compare:@"smalldatetime"]==NSOrderedSame)
        {
            return [self sqlite3_column_Date:stmt Formatter:DATEFORMATTER column:column];
        }
        else if ([type compare:@"decima"]==NSOrderedSame||[type compare:@"float"]==NSOrderedSame||[type compare:@"money"]==NSOrderedSame||[type compare:@"numeric"]==NSOrderedSame||[type compare:@"real"]==NSOrderedSame)
        {
            return [NSNumber numberWithDouble:[self sqlite3_column_Double:stmt column:column]];
        }
        else if([type compare:@"float"]==NSOrderedSame||[type compare:@"smallmoney"]==NSOrderedSame)
        {
            return [NSNumber numberWithFloat:[self sqlite3_column_float:stmt column:column]];
        }
    }
    @catch (NSException *exception) {
        return nil;
    }
    
    
    
}
-(NSString*)sqlite3_column_String:(sqlite3_stmt*)stmt column:(NSInteger) column{
    return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, (int)column)];
}
-(NSInteger)sqlite3_column_Int:(sqlite3_stmt*)stmt column:(NSInteger) column{
    return sqlite3_column_int(stmt, (int)column);
}
-(double)sqlite3_column_Double:(sqlite3_stmt*)stmt column:(NSInteger) column{
    return sqlite3_column_double(stmt, (int)column);
}
-(float)sqlite3_column_float:(sqlite3_stmt *)stmt column:(NSInteger)column{
    return sqlite3_column_double(stmt, (int)column);
}
-(NSDate*)sqlite3_column_Date:(sqlite3_stmt*)stmt Formatter:(NSString*) formatter  column:(NSInteger) column{
    NSDateFormatter *df=[[NSDateFormatter alloc]init];
    [df setDateFormat:formatter];
    NSString* str=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt,(int)column)];
    return [df dateFromString:str];
}
-(BOOL)sqlite3_column_Bool:(sqlite3_stmt *)stmt column:(NSInteger)column{
    @try {
        NSString* str=[[NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt,(int)column)] lowercaseString];
        if([str compare:@"yes"]==NSOrderedSame||[str compare:@"true"]==NSOrderedSame||[str compare:@"1"]==NSOrderedSame)
            return YES;
        else
            return NO;
        
    }
    @catch (NSException *exception) {
        return NO;
    }
    
}
-(void)sqlite3_bind_String:(sqlite3_stmt*)stmt String:(NSString*) value column:(NSInteger) column{
    sqlite3_bind_text(stmt, (int)column, [value UTF8String], -1,NULL);
}
-(void)sqlite3_bind_Int:(sqlite3_stmt*)stmt Int:(NSInteger) value column:(NSInteger) column{
    sqlite3_bind_int(stmt, (int)column, (int)value);
}
-(void)sqlite3_bind_Double:(sqlite3_stmt*)stmt Double:(double) value column:(NSInteger) column{
    sqlite3_bind_double(stmt, (int)column, value);
}
-(void)sqlite3_bind_float:(sqlite3_stmt*)stmt Float:(float) value column:(NSInteger) column{
    sqlite3_bind_double(stmt, (int)column, value);
}
-(void)sqlite3_bind_Date:(sqlite3_stmt*)stmt Date:(NSDate*) date Formatter:(NSString*) formatter  column:(NSInteger) column{
    sqlite3_bind_text(stmt, (int)column, [[ToolMethod DateToString:date formatString:formatter ] UTF8String], -1,NULL);
}
-(void)sqlite3_bind_Bool:(sqlite3_stmt*)stmt BOOL:(BOOL) value column:(NSInteger) column{
    sqlite3_bind_text(stmt, (int)column, [value?@"1":@"0" UTF8String], -1, NULL);
    
}





@end
