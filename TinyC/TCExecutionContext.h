//
//  TCContext.h
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//

#import <Foundation/Foundation.h>
#import "TCSyntaxNode.h"
#import "TCError.h"
#import "TCValue.h"
#import "TCRuntimeSymbolTable.h"
#import "TCStorageManager.h"

@class TCFunction;

int typeSize(int t );

@interface TCExecutionContext : NSObject

{
    TCStorageManager* _storage;
}

@property TCSyntaxNode * module;
@property TCSyntaxNode *block;
@property int blockPosition;
@property TCRuntimeSymbolTable * symbols;
@property TCExecutionContext * parent;
@property TCError * error;
@property BOOL debug;
@property NSArray * arguments;
@property TCSyntaxNode *returnInfo;
@property TCRuntimeSymbol * lastSymbol;
@property NSMutableArray * importedArguments;
@property BOOL assertAbort;

-(instancetype) initWithStorage:(TCStorageManager*) storage;
-(TCValue*) execute:(TCSyntaxNode*) tree withSymbols:(TCRuntimeSymbolTable *) symbols;
-(TCValue*) execute:(TCSyntaxNode*) tree;
-(TCValue *) execute:(TCSyntaxNode *)tree entryPoint:(NSString*) entryName;
-(TCValue *) execute:(TCSyntaxNode *)tree entryPoint:(NSString*) entryName withArguments:(NSArray*) arguments;
-(TCSyntaxNode*) findEntryPoint:(NSString*)entryName;
-(TCFunction*) findBuiltin:(NSString*)entryName;
-(BOOL) hasUnresolvedNames:(TCSyntaxNode*) node;
-(void) module:(TCSyntaxNode*) tree;

@end
