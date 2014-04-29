//
//  ExpressionInterpreter.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>
#import "TCSyntaxNode.h"
#import "TCValue.h"
#import "TCError.h"
#import "TCSymbolTable.h"
#import "TCStorageManager.h"
#import "TCExecutionContext.h"

@interface TCExpressionInterpreter : NSObject
@property BOOL debug;
@property TCError* error;
@property TCStorageManager *storage;
@property TCExecutionContext *context;

-(TCValue *) evaluate:(TCSyntaxNode* ) node withSymbols:(TCSymbolTable*) symbols;
-(TCValue *) evaluateString:(NSString*) string;
-(TCValue*) functionCall:(TCSyntaxNode *) node withSymbols:(TCSymbolTable*)symbols;
-(TCValue*) executeFunction:(NSString*) name withArguments:(NSArray*) arguments;

@end
