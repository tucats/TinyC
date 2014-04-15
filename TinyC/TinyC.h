//
//  TinyC.h
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//

#import <Foundation/Foundation.h>
#import "TCError.h"
#import "TCValue.h"

typedef enum {
    TCDebugNone = 0,
    TCDebugTokens = 1,
    TCDebugParse = 2,
    TCDebugTrace = 4,
    TCDebugStorage = 8
} TCDebugFlag;


@class TCParser;
@class TCSyntaxNode;

@interface TinyC : NSObject

{
    TCValue * functionResult;
    TCParser * parser;
    TCSyntaxNode * parseTree;
    TCDebugFlag debugFlags;
}

@property TCValue* result;
@property NSString * moduleName;

-(TCError*) compileString:(NSString*) source;

-(TCError*) compileFile:(NSString*) path;

-(TCError*) execute;

-(TCError*) executeReturningValue:(TCValue**) result;

-(void) setDebug:(TCDebugFlag) debugFlag;
-(BOOL) debugTokens;
-(BOOL) debugParse;
-(BOOL) debugTrace;
-(BOOL) debugStorage;

@end
