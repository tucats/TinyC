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
#import "TCSymbolTable.h"
#import "TCStorageManager.h"
#import "TCFunction.h"

int typeSize(int t );

@interface TCExecutionContext : NSObject

{
    TCStorageManager* _storage;
}

@property TCSyntaxNode * module;
@property TCSyntaxNode *block;
@property int blockPosition;
@property TCSymbolTable * symbols;
@property TCExecutionContext * parent;
@property TCError * error;
@property BOOL debug;
@property NSArray * arguments;
@property TCSyntaxNode *returnInfo;
@property TCSymbol * lastSymbol;
@property NSMutableArray * importedArguments;


-(instancetype) initWithStorage:(TCStorageManager*) storage;
-(TCValue*) execute:(TCSyntaxNode*) tree withSymbols:(TCSymbolTable *) symbols;
-(TCValue*) execute:(TCSyntaxNode*) tree;
-(TCValue *) execute:(TCSyntaxNode *)tree entryPoint:(NSString*) entryName;
-(TCValue *) execute:(TCSyntaxNode *)tree entryPoint:(NSString*) entryName withArguments:(NSArray*) arguments;
-(TCSyntaxNode*) findEntryPoint:(NSString*)entryName;
-(TCFunction*) findBuiltin:(NSString*)entryName;
-(BOOL) hasUnresolvedNames:(TCSyntaxNode*) node;
-(void) module:(TCSyntaxNode*) tree;

@end
