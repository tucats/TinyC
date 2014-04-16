//
//  TinyC.m
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//

#import "TinyC.h"
#import "TCValue.h"
#import "TCParser.h"
#import "TCContext.h"
#import "TCModuleParser.h"


@implementation TinyC

-(TCError*) compileFile:(NSString *)path
{
    NSError * error;

    NSString * source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if( error != nil) {
        //printf("File error %s\n", [[error localizedDescription] UTF8String]);
        return [[TCError alloc]initWithCode:TCERROR_FATAL withArgument:[error localizedDescription]];
    }
    
    _moduleName = [[path lastPathComponent] stringByDeletingPathExtension];
    return [self compileString:source];
}

-(TCError*) compileString:(NSString *)source
{
    
    parser = [[TCParser alloc]init];
    [parser lex:source];
    if( self.debugTokens)
        [parser dump];
    _moduleName = @"__STRING__";
    return parser.error;
}

-(TCError*) executeReturningValue:(TCValue *__autoreleasing *)result
{
    TCError * error = [self execute];
    if( result != nil )
        *result = functionResult;
    
    return error;
    
}


-(TCError* ) execute
{
    TCError * error;
    TCModuleParser* module = [[TCModuleParser alloc]init];
    TCSyntaxNode * tree = [module parse:parser name:_moduleName];
    error = parser.error;
    
    functionResult = nil;
    if( error != nil) {
        return error;
    }
    else {
 
        // If requested by the user, dump the tree now.
        
        if( self.debugParse ) {
            [tree dumpTree];
        }
  
        // Allocate the storage manager we will use.
        TCStorage * storage = [[TCStorage alloc]initWithStorage:65536];
        storage.debug = self.debugStorage;
        
        // Now that we have storage, search for string scalar values
        // that really need to be char* pointing to static storage.
        
        [self allocateScalarString:tree storage: storage];
        
        // Create execution context and run
        
        TCContext * execution = [[TCContext alloc]initWithStorage:storage];
        execution.debug = self.debugTrace;
        
        functionResult = [execution execute:tree
                                 entryPoint:@"main"
                              withArguments:@[ [[TCValue alloc]initWithInt:10] ]];
        return [execution error];
    }

}

/**
 Search a parse tree (recursively as needed) and locate any SCALAR string loads.
 Convert those to char* loads and allocate space in the storage area for them.
 @param tree the parse tree to evaluate
 @param storage the storage allocator to use
 @return count of nodes were found that need replacing
 */

-(long) allocateScalarString:(TCSyntaxNode *)tree storage:(TCStorage *)storage
{
    long count = 0;
    
    if( tree.nodeType == LANGUAGE_SCALAR && tree.action == TOKEN_STRING) {
        long stringLength = tree.spelling.length + 1;
        long base = [storage alloc:stringLength];
        const char * data = [tree.spelling cStringUsingEncoding:NSUTF8StringEncoding];
        for( int ix = 0; ix < stringLength; ix++)
            storage.buffer[base+ix] = data[ix];
        storage.buffer[base+stringLength] = 0;
        tree.action = TCVALUE_CHAR + TCVALUE_POINTER;
        tree.argument = [NSNumber numberWithLong:base];
        if(debugFlags & TCDebugStorage) {
            NSLog(@"STORAGE: allocated %ld byte string constant for %@ at %@",
                  stringLength, tree.spelling, tree.argument);
        }
    }
    else if( tree.subNodes ) {
        for( int ix = 0; ix < tree.subNodes.count; ix++ ) {
            TCSyntaxNode * child = (TCSyntaxNode*) tree.subNodes[ix];
            [self allocateScalarString:child storage:storage];
        }
    }
    return count;
}


-(BOOL) debugParse
{
    return (debugFlags & TCDebugParse) ? YES: NO;
}

-(BOOL) debugTokens
{
    return (debugFlags & TCDebugTokens)? YES : NO;
}

-(BOOL) debugTrace
{
    return (debugFlags & TCDebugTrace)? YES : NO;
}

-(BOOL) debugStorage
{
    return (debugFlags & TCDebugStorage)? YES : NO;
}

-(void) setDebug:(TCDebugFlag)debugFlag
{
    debugFlags = debugFlag;
}

@end
