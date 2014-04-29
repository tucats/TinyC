//
//  TinyC.m
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//  MAIN CLASS
//
//  This class defines the generalized object for TinyC.  It allows the caller
//  to specify a file or string containing a TinyC program, and comiple it for
//  execution.  The compilation is maintained as a property of the TinyC object;
//  there should be one instance for each module compiled.
//
//  Once compiled, the object can be executed repeatedly by calling the appropriate
//  method.


#import "TinyC.h"
#import "TCValue.h"
#import "TCSymtanticParser.h"
#import "TCExecutionContext.h"
#import "TCModuleParser.h"

BOOL assertAbort = NO;

@implementation TinyC

-(TCError*) compileFile:(NSString *)path
{
    NSError * error;
    
    // Build a string that contains the contents of the file in memory.  If an error occurs, wrap
    // it in a TCError value and return it.
    NSString * source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if( error != nil) {
        return [[TCError alloc]initWithCode:TCERROR_FATAL withArgument:[error localizedDescription]];
    }
    
    // Successfully read; formulate the module name by using the last component of the path name
    // with any extension removed.  So /Users/tom/Projects/TinyC/simple.c becomes module "simple".
    _moduleName = [[path lastPathComponent] stringByDeletingPathExtension];
    
    // Now compile the string and capture the appropriate return code, or nil if no errors
    // occurred.
    TCError * compileError = [self compileString:source];
    
    // Compilation done; formulate the module name by using the last component of the path name
    // with any extension removed.  So /Users/tom/Projects/TinyC/simple.c becomes module "simple".
    // This must be done after the compileString call since it initializes the module name to
    // be "__STRING__"
    _moduleName = [[path lastPathComponent] stringByDeletingPathExtension];
    
    
    return compileError;
}

-(TCError*) compileString:(NSString *)source
{
    TCError *error;
    
    parser = [[TCSymtanticParser alloc]init];
    [parser lex:source];
    if( self.debugTokens)
        [parser dump];
    _moduleName = @"__STRING__";
    
    TCModuleParser* module = [[TCModuleParser alloc]init];
    TCSyntaxNode * tree = [module parse:parser name:_moduleName];
    error = parser.error;
    
    // If the parse resulted in an error, bail out.
    if( error != nil) {
        return error;
    }
    
    
    // If requested by the user, dump the tree now.
    
    if( self.debugParse ) {
        [tree dumpTree];
    }
    
    // Allocate the storage manager we will use.
    
    if( _memorySize == 0 )
        _memorySize = 65536;
    
    self.storage = [[TCStorageManager alloc]initWithStorage:_memorySize];
    self.storage.debug = self.debugStorage;
    
    // Create execution context and check to see if there are
    // unresolved symbols
    
    context = [[TCExecutionContext alloc]initWithStorage:self.storage];
    context.debug = self.debugTrace;
    context.module = tree;
    if([context hasUnresolvedNames:tree]) {
        return context.error;
    }
    
    // Now that we have storage and the tree is free of obvious
    // errors, search for string scalar values
    // that really need to be char* pointing to static storage.
    // Always start with an empty dictionary. After the allocation
    // we no longer need the dictionary and can free it up...
    
    _stringPool = [NSMutableDictionary dictionary];
    [self allocateScalarStrings:tree storage: self.storage];
    _stringPool = nil;
    
    _result = nil;
    
    return parser.error;
}

-(TCError*) executeReturningValue:(TCValue *__autoreleasing *)result
{
    TCError * error = [self execute];
    if( result != nil )
        *result = _result;
    
    return error;
    
}


-(TCError* ) execute
{
    
    // Execute the symantic tree.
    
    _result = [context execute:context.module
                             entryPoint:@"main"
                          withArguments:@[ [[TCValue alloc]initWithInt:10] ]];
    
    // After we're done, do we need to dump out memory usage stats?
    
    if( debugFlags & TCDebugMemory) {
        NSLog(@"MEMORY: total runtime memory (in bytes):       %8ld", _storage.size);
        NSLog(@"MEMORY: Maximum active automatic stack frames: %8d",  _storage.frameCount);
        NSLog(@"MEMORY: Maximum automatic storage allocated:   %8ld", _storage.autoMark);
        NSLog(@"MEMORY: Maximum dynamic   storage allocated:   %8ld", _storage.dynamicMark);
        NSLog(@"MEMORY: Unused runtime memory:                 %8ld",
              _storage.size - (_storage.autoMark + _storage.dynamicMark + 8));
    }

    return [context error];
}


/**
 Search a parse tree (recursively as needed) and locate any SCALAR string loads.
 Convert those to char* loads and allocate space in the storage area for them.
 @param tree the parse tree to evaluate
 @param storage the storage allocator to use
 @return count of nodes were found that need replacing
 */

-(long) allocateScalarStrings:(TCSyntaxNode *)tree storage:(TCStorageManager *)storage
{
    long count = 0;
    
    if( tree.nodeType == LANGUAGE_SCALAR && tree.action == TOKEN_STRING) {
        
        long base = 0L;
        long stringLength = tree.spelling.length + 1;
        BOOL inPool = NO;
        
        // Do we already have a copy of this same string?
        
        NSNumber * stringAddress = [_stringPool objectForKey:tree.spelling];
        if( stringAddress) {
            base = stringAddress.longValue;
            inPool = YES;
        } else {
            // Allocate new space for the string
            base = [storage allocUnpadded:stringLength];
            
            // Copy it to the memory area.
            
            const char * data = [tree.spelling cStringUsingEncoding:NSUTF8StringEncoding];
            for( int ix = 0; ix < stringLength; ix++)
                storage.buffer[base+ix] = data[ix];
            storage.buffer[base+stringLength] = 0;
            
            // Add it to the pool for later possible re-use
            [_stringPool setObject:[NSNumber numberWithLong:base] forKey:tree.spelling];
            
        }
        
        // Update the node to point to the string pool storage area assigned
        
        tree.action = TCVALUE_CHAR + TCVALUE_POINTER;
        tree.argument = [NSNumber numberWithLong:base];
        if(debugFlags & TCDebugStorage) {
            
            NSLog(@"STORAGE: %@ %ld byte string constant \"%@\" @ %@",
                  inPool ? @"re-used pooled" : @"copied",
                  stringLength, tree.spelling, tree.argument);
        }
    }
    else if( tree.subNodes ) {
        for( int ix = 0; ix < tree.subNodes.count; ix++ ) {
            TCSyntaxNode * child = (TCSyntaxNode*) tree.subNodes[ix];
            [self allocateScalarStrings:child storage:storage];
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

-(void) setSigAbort:(BOOL)flag
{
    assertAbort = flag;
}
@end
