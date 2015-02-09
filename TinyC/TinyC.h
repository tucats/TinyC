//
//  TinyC.h
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
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

#import <Foundation/Foundation.h>
#import "TCError.h"
#import "TCValue.h"
@class TCStorageManager;

/**
 Flags indicating debug operations to be performed during the compilation and
 execution of TinyC programs.
 */

typedef enum {
    /** No debug flags set */
    TCDebugNone = 0,
    
    /** Dump out the token list from the lexical processor */
    TCDebugTokens = 1,
    
    /** Dump out the abstract syntax tree generated by the parser */
    TCDebugParse = 2,
    
    /** Produce trace records as the AST is executed */
    TCDebugTrace = 4,
    
    /** Produce trace records when the TinyC program accesses memory */
    TCDebugStorage = 8,
    
    /** Produce a summary report at the end of execution of memory usage */
    TCDebugMemory = 16,
    
    /** Are calls to _assert that fail considered fatal, or ignored? */
    TCFatalAsserts = 32,
    
    /** Is the random number generator deterministic or truly random? */
    TCNonRandomNumbers = 64
    
} TCFlag;


@class TCLexicalScanner;
@class TCSyntaxNode;
@class TCExecutionContext;


@interface TinyC : NSObject

{
    
    /** The lexical scanner used to compile the TinyC program */
    TCLexicalScanner * scanner;
    
    /** The abstract syntax tree generated by the parser */
    
    TCSyntaxNode * parseTree;
    
    /** The debug flag(s) in effect for this object.  This may be
        the sum of one or more of the TCFlag values.
     */
    TCFlag flags;
    
    /** This is the context used to execute this program code. */
    TCExecutionContext * context;
    
}


/**
 * Class Factory to allocate a new instance of the compiler and runtime with a given
 * memory size and debug flag state.
 * @param initialMemorySize the amount of memory (in bytes) that will be allocated to run the program
 * @param debugFlags the runtime flag settings for commpilation and execution of the program
 * @return a new instance of TinyC ready to accept source for compilation and execution.
 */
+(id)allocWithMemory:(long) initialMemorySize flags:(TCFlag)debugFlags;

/**
 * Short-cut initialization that creates an object and specifies it's memory footprint
 * and debug flag settings.
 * @param initialMemorySize the amount of memory (in bytes) that will be allocated to run the program
 * @param debugFlags the runtime flag settings for commpilation and execution of the program
 * @return a new instance of TinyC ready to accept source for compilation and execution.
 */
-(id)initWithMemory:(long)initialMemorySize flags:(TCFlag)debugFlags;

/** The result of the program's execution */
@property TCValue* result;

/** The name of the module being compiled or executed, formed from the
    source file name.  If compiled from a string, this is the value "__string__"
 */
@property NSString * moduleName;

/** This is used to list the string constants used in the program during
    the pre-execution scan to move them into dynamic storage and pooled
    so there is a single copy of each string value.
 */
@property NSMutableDictionary * stringPool;

/** The total number of bytes of memory available for the runtime of
    the TinyC program.
 */
@property long memorySize;

/** The pseudo-virtual memory manager for handling automatic, dynamic,
    and global storage for the TinyC runtime
 */
@property TCStorageManager * storage;

/** The argv[] array for this execution, if any */
@property NSMutableArray * arguments;

/**
 Given a string containing the text of a TinyC module, compile it and
 prepare it for execution.
 @param source the NSString containing the input source
 @param the module name to assign
 @returns nil if no error occured, else a description of the error.
 */
-(TCError*) compileString:(NSString *)source module:(NSString*) moduleName;

/**
 Given a text file containing the text of a TinyC module, compile it and
 prepare it for execution. The module name is taken from the file name.
 @param path the NSString containing the name of the input file.
 @returns nil if no error occured, else a description of the error.
 */
-(TCError*) compileFile:(NSString*) path;

/**
 Execute the previously-compiled program source.  
 @returns nil if there was no error, or else a description of the runtime
 error.  The program result code can be found in the result property.
 */
-(TCError*) execute;

/**
 Helper function to execute a program with an argument list.
 @param argList the arguments to pass to the program
 @return nil if success, else an error code
 */

-(TCError*) executeWithArguments:(NSMutableArray*) argList;

/**
 Helper function to execute a program with an argument list and
 return a result.
 */
-(TCError*) executeWithArguments:(NSMutableArray *)argList
                  returningValue:(TCValue *__autoreleasing*) result;

    
/**
 A helper function; this calls execute and then fetches the result value
 and writes it to the supplied location. 
 @param result a pointer to a TCValue object which will hold the result when
 the program completes executeion.  If the pointer is nil, no return value
 is passed back, though you can still get the result in the "result" property
 of the object.
 @returns nil if no errors were signalled during program execution, or a
 description of the runtime error.
 */
 -(TCError*) executeReturningValue:(TCValue**) result;

/**
 This function scans the parse tree and allocates static storage from the
 available virtual storage for the program for any string constants in the
 program, and modifies the parse tree accordingly so the allocated storage
 is referenced instead of a string constant in the parse tree itself.  This
 is run automatically when the [...execute] method is called.
 @param tree the abstract syntax tree created by the compilation of the 
 source code.
 @param the active storage assigned to this object for program execution.
 @returns a count of the number of bytes of runtime storage that were
 assigned to string constant values.
 */
-(long) allocateScalarStrings:(TCSyntaxNode*) tree storage:(TCStorageManager*) storage;
 
 /**
  Set the debug flag for this object.  The debug flag is 
  @param debugFlag a summation of the
  desired TCDebugFlag values.
 */
-(void) setDebug:(TCFlag) debugFlag;

/** Accessor function to determine if the TCDebugTokens flag is set */
-(BOOL) debugTokens;

/** Accessor function to determine if the TCDebugParse flag is set */
-(BOOL) debugParse;

/** Accessor function to determine if the TCDebugTrace flag is set */
-(BOOL) debugTrace;

/** Accessor function to determine if the TCDebugStorage flag is set */
-(BOOL) debugStorage;



@end
