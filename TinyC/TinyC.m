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
    TCError * compileError = [self compileString:source module:_moduleName];
    
    return compileError;
}

-(TCError*) compileString:(NSString *)source module:(NSString*) moduleName
{
    TCError *error;
    
    parser = [[TCSymtanticParser alloc]init];
    [parser lex:source];
    if( self.debugTokens)
        [parser dump];
    if(moduleName != nil)
        _moduleName = moduleName;
    else
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
    // Initialize the random number generator state unless the flag is
    // set to use deterministic random numbers
    
    if( flags & TCNonRandomNumbers)
        srandom(0);
    else
        srandomdev();
    
    // Make sure the flag indicating if asserts are fatal in this execution
    // is copied into the execution context.  We do this now since it could
    // have been (re)set by the caller after compilation but before execution.
    context.assertAbort = (BOOL) (flags & TCFatalAsserts);
    
    // Copy the argument list to runtime memory
    
    int argc = 0;
    long argv = 0L;
    
    if( _arguments != nil) {
        argc = (int) _arguments.count;
        argv = [_storage allocateDynamic:argc*sizeof(char*)];
        for( int ix = 0; ix < argc; ix++ ) {
            NSString * arg = [_arguments objectAtIndex:ix];
            long bytes = arg.length + 1;
            long argp = [_storage allocateDynamic:bytes];
            if( self.debugStorage)
                NSLog(@"STORAGE: store argument %d, \"%@\" at %ld",
                      ix, arg, argp);
            for( int cp = 0; cp < arg.length; cp++) {
                [_storage setChar:[arg characterAtIndex:cp] at:argp+cp];
            }
            [_storage setChar:0 at:argp+bytes];

            [_storage setLong:argp at:argv+(ix*sizeof(long))];
        }
    }
    
    // Execute the symantic tree.
    
    TCValue * argcValue = [[TCValue alloc]initWithInt:argc];
    
    TCValue * argvValue = [[[TCValue alloc]initWithLong:argv] makePointer:TCVALUE_POINTER_CHAR];
    
    _result = [context execute:context.module
                             entryPoint:@"main"
                          withArguments:@[ argcValue, argvValue ]];
    
    // After we're done, do we need to dump out memory usage stats?
    
    if( flags & TCDebugMemory) {
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
        if(flags & TCDebugStorage) {
            
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
    return (flags & TCDebugParse) ? YES: NO;
}

-(BOOL) debugTokens
{
    return (flags & TCDebugTokens)? YES : NO;
}

-(BOOL) debugTrace
{
    return (flags & TCDebugTrace)? YES : NO;
}

-(BOOL) debugStorage
{
    return (flags & TCDebugStorage)? YES : NO;
}

-(void) setDebug:(TCFlag)debugFlag
{
    flags = debugFlag;
}

@end
