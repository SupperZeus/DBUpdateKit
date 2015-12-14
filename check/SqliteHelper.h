

#import <Foundation/Foundation.h>
#import <sqlite3.h>
@protocol SqliteHelperDelegate <NSObject>
-(void)configurationParameterForStmt:(sqlite3_stmt*) stmt forTag:(NSInteger) tag ;//配置参数
-(void)configurationParameterForStmt:(sqlite3_stmt*) stmt forTag:(NSInteger) tag forRow:(NSInteger) row;//插入多行时调用
-(id)ManageValueForSelect:(sqlite3_stmt*) stmt forTag:(NSInteger) tag ;//手动将查询结果赋值给模型类
@end
@interface SqliteHelper : NSObject
{
    sqlite3 *sqlite;
    NSString *filePath;
}
@property(nonatomic,assign)id<SqliteHelperDelegate> delegate;
-(id)initWithDataPath:(NSString*)dataPath;
-(int)OpenSqlite;
-(int)BeginTransaction;
-(int)CommitTransaction;
-(int)RollbackTransaction;
-(void)CloseSqlite;
//当SQL语句比较复杂时使用
-(int)ExecSQL:(NSString*) sql throwEx:(BOOL) throwEx;
-(int)UpdateData:(NSString*) sql forTag:(NSInteger) tag throwEx:(BOOL) throwEx;
-(void)InsertData:(NSString*) sql forTag:(NSInteger) tag count:(NSInteger)count throwEx:(BOOL) throwEx;
-(NSMutableArray*)selectTable:(NSString*) sql forTag:(NSInteger) tag;



//适用于单个实体的数据库操作
//-(void)InsertXubModel:(XubModel*)xubModel throwEx:(BOOL) throwEx;
//-(NSMutableArray*)selectXubModel:(NSString*) sql forXubModel:(NSString*) xubModelName params:(NSArray*)params paramtypes:(NSArray*)types ;
//-(BOOL)checkXubModelExist:(XubModel*)xubModel;
//-(void)updateXubModel:(XubModel*)xubModel throwEx:(BOOL) throwEx;
//-(void)deleteXubModel:(XubModel*)xubModel throwEx:(BOOL) throwEx;

-(NSString*)sqlite3_column_String:(sqlite3_stmt*)stmt column:(NSInteger) column;
-(NSInteger)sqlite3_column_Int:(sqlite3_stmt*)stmt column:(NSInteger) column;
-(float)sqlite3_column_float:(sqlite3_stmt*)stmt column:(NSInteger) column;
-(NSDate*)sqlite3_column_Date:(sqlite3_stmt*)stmt Formatter:(NSString*) formatter  column:(NSInteger) column;
-(BOOL)sqlite3_column_Bool:(sqlite3_stmt *)stmt column:(NSInteger)column;
-(void)sqlite3_bind_String:(sqlite3_stmt*)stmt String:(NSString*) value column:(NSInteger) column;
-(void)sqlite3_bind_Int:(sqlite3_stmt*)stmt Int:(NSInteger) value column:(NSInteger) column;
-(void)sqlite3_bind_Double:(sqlite3_stmt*)stmt Double:(double) value column:(NSInteger) column;
-(void)sqlite3_bind_float:(sqlite3_stmt*)stmt Float:(float) value column:(NSInteger) column;
-(void)sqlite3_bind_Date:(sqlite3_stmt*)stmt Date:(NSDate*) date Formatter:(NSString*) formatter  column:(NSInteger) column;
-(void)sqlite3_bind_Bool:(sqlite3_stmt*)stmt BOOL:(BOOL) value column:(NSInteger) column;

+(SqliteHelper*)shareInstance;

@end
