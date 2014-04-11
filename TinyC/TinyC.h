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

@class TCParser;
@class TCSyntaxNode;

@interface TinyC : NSObject

{
    TCValue * functionResult;
    TCParser * parser;
    TCSyntaxNode * parseTree;
}

@property BOOL debug;
@property TCValue* result;
@property NSString * moduleName;

-(TCError*) compileString:(NSString*) source;

-(TCError*) compileFile:(NSString*) path;

-(TCError*) execute;

-(TCError*) executeReturningValue:(TCValue**) result;

-(void) setDebug:(BOOL) debugFlag;

@end
