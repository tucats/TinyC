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
#import "TCRuntimeSymbolTable.h"
#import "TCStorageManager.h"
#import "TCExecutionContext.h"

@interface TCExpressionInterpreter : NSObject

/** Flag indicating if runtime logging is to be done during expression processing */
@property BOOL debug;

/** This holds the last error from an expression evaluation */
@property TCError* error;

/** This is a pointer to the runtime memory storage manager */
@property TCStorageManager *storage;

/** This is a pointer to the current execution context executing the expression. */
@property TCExecutionContext *context;

-(TCValue *) evaluate:(TCSyntaxNode* ) node
          withSymbols:(TCRuntimeSymbolTable*) symbols;

-(TCValue *) evaluateString:(NSString*) string;

-(TCValue*) functionCall:(TCSyntaxNode *) node
             withSymbols:(TCRuntimeSymbolTable*)symbols;

-(TCValue*) executeFunction:(NSString*) name
              withArguments:(NSArray*) arguments
                     atNode:(TCSyntaxNode*)node;

@end
