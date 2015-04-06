//
//  TCContext.m
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//

#import "TCExecutionContext.h"
#import "TCSyntaxNode.h"
#import "TCRuntimeSymbolTable.h"
#import "TCError.h"
#import "TCValue.h"
#import "TCToken.h"
#import "TCExpressionInterpreter.h"
#import "TCFunction.h"
#import "TinyC.h"

TCExecutionContext* activeContext;

#pragma mark - Utilities

int typeSize(int t )
{
    switch(t) {
        case TCVALUE_CHAR:
        case TOKEN_DECL_CHAR:
            return sizeof(char);
        case TCVALUE_DOUBLE:
        case TOKEN_DECL_DOUBLE:
            return sizeof(double);
        case TCVALUE_INT:
        case TOKEN_DECL_INT:
            return sizeof(int);
        case TCVALUE_LONG:
        case TOKEN_DECL_LONG:
            return sizeof(long);
        case TCVALUE_FLOAT:
        case TOKEN_DECL_FLOAT:
            return sizeof(float);
            
        default:
            return 1;
    }
}
char * typeMap(TokenType theType)
{
    static char horrible_static[8];
    
    switch ((int)theType) {
        case TCVALUE_INT:
        case TOKEN_DECL_INT:
            return "int";
            break;
            
        case TCVALUE_LONG:
        case TOKEN_DECL_LONG:
            return "long";
            break;
            
        case TCVALUE_FLOAT:
            
        case TOKEN_DECL_FLOAT:
            return "float";
            break;
            
        case TCVALUE_DOUBLE:
        case TOKEN_DECL_DOUBLE:
            return "double";
            break;
            
        case TCVALUE_CHAR:
        case TOKEN_DECL_CHAR:
            return "char";
            break;
            
        default:
            sprintf(horrible_static, "Type %d", theType);
            return horrible_static;
    }
}


TCValue* coerceType(TCValue* value, TokenType theType)
{
    TCValueType newType;
    
    // Assuming we actually got a token type, convert that to the
    // appropriate corresponding value specification.
    
    switch( theType) {
        case TOKEN_DECL_INT:
            newType = TCVALUE_INT;
            break;
        case TOKEN_DECL_LONG:
            newType = TCVALUE_LONG;
            break;
        case TOKEN_DECL_DOUBLE:
            newType = TCVALUE_DOUBLE;
            break;
        case TOKEN_DECL_FLOAT:
            newType = TCVALUE_FLOAT;
            break;
        case TOKEN_DECL_CHAR:
            newType = TCVALUE_CHAR;
            break;
            
        default:
            newType = (TCValueType)theType;
    }
    
    return [value castTo:newType];
}

@implementation TCExecutionContext

#pragma mark - Initialization

-(instancetype)initWithStorage:(TCStorageManager*) storage
{
    if(( self = [super init])) {
        _storage = storage;
    }
    
    return self;
}

-(void) module:(TCSyntaxNode *)tree
{
    activeContext = self;
    activeContext.module = tree;
}


#pragma mark - Execution

-(TCValue*)execute:(TCSyntaxNode *)tree withSymbols:(TCRuntimeSymbolTable *)symbols
{
    self.symbols = symbols;
    return [self execute:tree];
}

-(TCValue *) execute:(TCSyntaxNode *)tree
{
    return [self execute:tree entryPoint:nil withArguments:nil];
}


-(TCValue *) execute:(TCSyntaxNode *)tree entryPoint:(NSString*) entryName
{
    return [self execute:tree entryPoint:entryName withArguments:nil];
    
}


-(TCValue *) execute:(TCSyntaxNode *)tree entryPoint:(NSString*) entryName withArguments:(NSArray*) arguments;

{
    
    if( !activeContext)
        activeContext = self;
    
    TCValue * result = [[TCValue alloc]initWithInt:0];
    
    if(_debug) {
        if( entryName != nil)
            NSLog(@"TRACE:   Searching MODULE for entrypoint %@", entryName);
        
    }
    
    // If there is an entry name, we have work to do to find the entry point,
    // manage arguments, etc.  If there is no entry name, then this is just a
    // recursive call to execute a nested block, usually.
    
    if( entryName != nil ) {
        activeContext.module = tree;
        tree = [self findEntryPoint:entryName];
    }
    
    int baseType = 0;
    int ix = 0;
    // Execute a statement or a block.
    
    switch( tree.nodeType) {
            
#pragma mark > continue
            
            // CONTINUE does nothing
        case LANGUAGE_CONTINUE:
            if(_debug)
                NSLog(@"TRACE:   CONTINUE, restart basic block from beginning");
            _error = [[TCError alloc]initWithCode:TCERROR_CONTINUE atNode:tree];
            return result;

#pragma mark > break
            // Break returns special return code
        case LANGUAGE_BREAK:
            if(_debug)
                NSLog(@"TRACE:   BREAK, exit basic block");
            _error = [[TCError alloc]initWithCode:TCERROR_BREAK atNode:tree];
            return nil;
            break;
            
#pragma mark > array and reference
            
        case LANGUAGE_ARRAY:
        case LANGUAGE_REFERENCE:
        {
            TCExpressionInterpreter *expInt = [[TCExpressionInterpreter alloc]init];
            expInt.storage = _storage;
            expInt.debug = _debug;
            expInt.context = self;
            
            return [expInt evaluate:tree withSymbols:_symbols];
        }
#pragma mark > dereference

        case LANGUAGE_DEREFERENCE:
        {
            // Process the subnodes, which must result in a pointer.  Get the value
            // of the pointer.
            TCExpressionInterpreter *expInt = [[TCExpressionInterpreter alloc]init];
            expInt.storage = _storage;
            expInt.debug = _debug;
            expInt.context = self;

            TCValue * address = [expInt evaluate:tree.subNodes[0] withSymbols:_symbols];
            if( address == nil ) {
                _error = expInt.error;
                return nil;
            }
            
            // @NODE need the base type of what we are dereferencing here!
            int baseType = TCVALUE_INT;
            
            return [_storage getValue:address.getLong ofType:baseType];
        }
            
#pragma mark > address

        case LANGUAGE_ADDRESS:
        {
            // Find the address of a target.  Right now we only support a single name.
            
            TCRuntimeSymbol * targetValue = nil;
            if( tree.spelling == nil ) {
                TCSyntaxNode *addressTree = (TCSyntaxNode*) tree.subNodes[0];
                result = [self execute:addressTree withSymbols:_symbols];
                if( result.getType < TCVALUE_POINTER)
                    result = [result makePointer:result.getType];
                return result;
            }
            
            
            targetValue = [_symbols findSymbol:tree.spelling];
            
            if( targetValue == nil ) {
                _error = [[TCError alloc]initWithCode:TCERROR_UNK_IDENTIFIER atNode:tree withArgument:tree.spelling];
                if( _debug )
                    NSLog(@"C_ERROR: %@", _error);
                return nil;
            }
            if(!targetValue.allocated) {
                NSLog(@"C_ERROR: attempt to write to unallocated variable %@", tree.spelling);
                return nil;
            }
            if( _debug )
                NSLog(@"TRACE:   Locate address of %@, %ld", tree.spelling, targetValue.address);
            result = [[[TCValue alloc]initWithLong:targetValue.address] makePointer:targetValue.type];
            
            return result;
        }
            
            // Most common case, a call to a function with no result or an assignment
#pragma mark > expression

        case LANGUAGE_EXPRESSION:
        {
            TCExpressionInterpreter * expInt = [[TCExpressionInterpreter alloc]init];
            expInt.debug = _debug;
            expInt.storage = _storage;
            expInt.context = self;

            
            result = [expInt evaluate:tree withSymbols:_symbols];
            if(expInt.error) {
                _error = expInt.error;
                return nil;
            }
        }
            break;
#pragma mark > entrypoint

        case LANGUAGE_ENTRYPOINT:
            
        {
            if( _debug)
                NSLog(@"TRACE:   Beginning execution of entrypoint %@", tree.spelling);
            
            if( [tree.spelling isEqualToString:RUNTIME_ENTRYPOINT])
                _isCoRoutine = TRUE;
            
            // The first subnode is the return type; squirrel that away.
            
            self.returnInfo = tree.subNodes[0];
            
            // The next ones are the argument list; the count not be less
            // than number of arguments provided. Assign the values to the
            //local variable initializer field.
            
            if( arguments.count < (tree.subNodes.count - 2)) {
                _error = [[TCError alloc]initWithCode:TCERROR_ARG_MISMATCH atNode:tree withArgument:nil];
                return nil;
            }
            
            if( tree.subNodes.count > 2 ) {
                _importedArguments = [NSMutableArray array];
                for( int ix = 0; ix < arguments.count; ix++ ) {
                    TCValue* argValue = (TCValue*) arguments[ix];
                    if((ix+1) >= tree.subNodes.count-1 ) {
                        if(_debug)
                            NSLog(@"TRACE:   warning, passed arg #%d(%@) has no matching function parameter", ix+1, argValue);
                        break;
                    }
                    TCSyntaxNode* localArg = tree.subNodes[ix+1];
                    TCSyntaxNode* localArgName = localArg.subNodes[0];
                    
                    // See if we need to cast each argument to the type
                    // of the caller so we don't read storage values incorrectly!!
                    
                    if( argValue.getType != localArg.action) {
                        if( _debug)
                            NSLog(@"TRACE:   Casting function parm #%d to %s", ix+1, typeMap(localArg.action));
                        argValue = [argValue castTo:localArg.action];
                    }
                    localArgName.argument = argValue;
                    [_importedArguments addObject:localArg ];
                    
                    if(_debug)
                        NSLog(@"TRACE:   Add arg #%d %@ of type %s to arglist",ix, localArgName.spelling, typeMap(localArg.action));
                }
            }
            // The final subnode is the code block to execute. Fetch that out and let's run it.
            
            tree = tree.subNodes[tree.subNodes.count-1];
            return [self execute:tree];
            
        }
#pragma mark > block

            // A group of statements executed sequentially
        case LANGUAGE_BLOCK:
        {
            
            // A block requires a new symbol context so symbols declared are local to the block
            
            TCRuntimeSymbolTable * scopedSymbols = [[TCRuntimeSymbolTable alloc]init];
            scopedSymbols.parent = self.symbols;
            self.symbols = scopedSymbols;
            self.error = nil;
            [_storage pushStorage];  // Make a new storage frame
            
            if( _importedArguments ) {
                NSArray * tempArglist = [_importedArguments copy];
                _importedArguments = nil;
                if( _debug)
                    NSLog(@"TRACE:   Importing %d arguments to local symbol table",
                          (int)tempArglist.count);
                
                for( int ix = 0; ix < tempArglist.count; ix ++ ) {
                    TCSyntaxNode * argDecl = (TCSyntaxNode*) tempArglist[ix];
                    [self execute:argDecl];
                }
                tempArglist = nil;
            }
            for( ix = 0; ix < tree.subNodes.count; ix++) {
                _blockPosition = ix;
                result = [self execute:tree.subNodes[ix] withSymbols:self.symbols];
                
                if( self.error.isContinue) {
                    // Resume at the start of the block
                    
                    break;
                }
                
                if( self.error.isBreak) {
                    break;
                }
                
                if( self.error.isReturn) {
                    return result;
                }
                
                if( self.error)
                    return nil;
            }
            
            // Now release the scoped block as long as we're not doing a branch
            // to a co-routine (lateral call, essentially).
            if(!_isCoRoutine) {
                self.symbols = scopedSymbols.parent;
                scopedSymbols = nil;
                [_storage popStorage];
            }
        }
            break;
#pragma mark > assignment

        case LANGUAGE_ASSIGNMENT:
        {
            // Step one, get the target expression.
            TCSyntaxNode * target = tree.subNodes[0];
            TCValue * targetAddress = [self execute:target withSymbols:_symbols];
            if( targetAddress == nil )
                return nil;
            
            // Step two, get the expression to assign.
            TCSyntaxNode * exp = tree.subNodes[1];
            TCExpressionInterpreter *expInt = [[TCExpressionInterpreter alloc]init];
            expInt.debug = _debug;
            expInt.storage = _storage;
            expInt.context = self;

            TCValue * value = [expInt evaluate:exp withSymbols:_symbols];
            if( expInt.error) {
                _error = expInt.error;
                return nil;
            }
            
            // Sanity check; the target address must be expressed with a type
            // that includes the POINTER designation.
            
            TCValueType targetType = targetAddress.getType;
            TCValueType actualType = targetType;

            if( targetType > TCVALUE_POINTER) {
                actualType = targetType - TCVALUE_POINTER;
            }
            
            if(value.getType != actualType) {
                value = [value castTo:actualType];
                if(_debug)
                    NSLog(@"TRACE:   Assignment cast to target type of %@", value.getTypeName);
            }
            [_storage setValue:value at:targetAddress.getLong];
            result = value;
        }
            break;
#pragma mark > if

        case LANGUAGE_IF:
        {
            TCSyntaxNode * condition = tree.subNodes[0];
            TCSyntaxNode * ifTrue = tree.subNodes[1];
            
            TCExpressionInterpreter * expInt = [[TCExpressionInterpreter alloc]init];
            expInt.debug = _debug;
            expInt.storage = _storage;
            expInt.context = self;

            TCValue * condValue = [expInt evaluate:condition withSymbols:_symbols];
            if( condValue.getLong ) {
                if(_debug)
                    NSLog(@"TRACE:   Condition value %@, execute true branch", condValue);
                result = [self execute:ifTrue withSymbols:_symbols];
            } else if( tree.subNodes.count > 2) {
                if(_debug)
                    NSLog(@"TRACE:   Condition value %@, execute false branch", condValue);
                result = [self execute:tree.subNodes[2] withSymbols:_symbols];
            } else if(_debug)
                NSLog(@"TRACE:   Condition value %@, nothing executed", condValue);
        }
            break;
            
#pragma mark > return

        case LANGUAGE_RETURN:
        {
            TCExpressionInterpreter * expInt = [[TCExpressionInterpreter alloc]init];
            expInt.debug = _debug;
            expInt.storage = _storage;
            expInt.context = self;

            result = [expInt evaluate:tree.subNodes[0] withSymbols:_symbols];
            if( expInt.error) {
                _error = expInt.error;
                return nil;
            }
            if( _debug) {
                NSLog(@"TRACE:   Returning block value %@", result);
            }
            
            if( _returnInfo ) {
                if(_debug) {
                    NSLog(@"TRACE:   Return type coerced to %s", typeMap(_returnInfo.action));
                }
                result = coerceType(result, _returnInfo.action);
            }
            //[_storage popStorage];
            return result;
        }
#pragma mark > declare

        case LANGUAGE_DECLARE:
            
            baseType = tree.nodeAction;
            
            for( ix = 0; ix < tree.subNodes.count; ix++) {
                TCSyntaxNode * declaration = tree.subNodes[ix];
                if(_storage) {
                    _lastSymbol = [_symbols newSymbol:declaration.spelling ofType:declaration.action storage:_storage];
                }
                else
                    NSLog(@"FATAL ERROR - NO STORAGE AVAILABLE");
                
                // Is there a static initial value?
                
                if( declaration.argument && _storage)
                    [_lastSymbol setValue: (TCValue*)declaration.argument storage:_storage];
                else if( !_storage)
                    NSLog(@"C_ERROR: declaration initializer with no storage allocation");
                
                // alternatively, there can be compiler-generated initialization code
                // that yeilds a value.
                
                if( declaration.subNodes[0]) {

                    TCSyntaxNode * initializer = declaration.subNodes[0];

                    TCExpressionInterpreter * expInt = [[TCExpressionInterpreter alloc]init];
                    expInt.debug = _debug;
                    expInt.storage = _storage;
                    expInt.context = self;

                    TCValue * initValue = [expInt evaluate:initializer withSymbols:_symbols];
                    if(expInt.error) {
                        _error = expInt.error;
                        return nil;
                    }
                    [_lastSymbol setValue:initValue storage:_storage];
                    _lastSymbol.size = typeSize(baseType);
                    
                }
                
                if( _debug) {
                    if( _lastSymbol.initialValue)
                        NSLog(@"TRACE:   Created new variable %@ with initial value %@", _lastSymbol, _lastSymbol.initialValue);
                    else
                        NSLog(@"TRACE:   Created new variable %@", _lastSymbol);
                }
            }
            
            break;
#pragma mark > for

            // for loop
        case LANGUAGE_FOR:
        {
            
            TCSyntaxNode * initClause = tree.subNodes[0];
            TCSyntaxNode * termClause = tree.subNodes[1];
            TCSyntaxNode * increment = tree.subNodes[2];
            TCSyntaxNode * block = tree.subNodes[3];
            
            // Execute the initializer once
            [self execute:initClause withSymbols:_symbols];
            
            // As long as the termination clause is false, loop...
            TCValue * condition = nil;
            while(1) {
                
                condition = [self execute:termClause withSymbols:_symbols];
                if( self.error)
                    return nil;
                
                if( condition.getLong == 0)
                    break;
                
                // run the block of code
                result = [self execute:block withSymbols:_symbols];
                if( self.error ) {
                    if( self.error.code == TCERROR_BREAK) {
                        self.error = nil;
                        break;
                    }
                    if( self.error.code == TCERROR_CONTINUE) {
                        self.error = nil;
                        // Fall through to run the incrementor
                    }
                }
                // And then the incrementer
                if( self.error)
                    return nil;
                [self execute:increment withSymbols:_symbols];
            }
            break;
        }
#pragma mark > while

            // while loop
        case LANGUAGE_WHILE:
        {
            
            TCSyntaxNode * termClause = tree.subNodes[0];
            TCSyntaxNode * block = tree.subNodes[1];
            
            
            // As long as the termination clause is false, loop...
            TCValue * condition = nil;
            while(1) {
                
                condition = [self execute:termClause withSymbols:_symbols];
                if( self.error)
                    return nil;
                if( condition.getLong == 0)
                    break;
                
                // run the block of code
                result = [self execute:block withSymbols:_symbols];
                if( self.error ) {
                    if( self.error.code == TCERROR_BREAK) {
                        self.error = nil;
                        break;
                    }
                }
                if( self.error.code == TCERROR_CONTINUE) {
                    self.error = nil;
                    continue;
                }
                
            }
            break;
        }

        default:
            self.error = [[TCError alloc]initWithCode:TCERROR_UNK_STATEMENT
                                               atNode:tree
                                         withArgument:[NSNumber numberWithInt:tree.nodeType]];
            return nil;
            
    }
    
    return result;
}

-(TCSyntaxNode*) findEntryPoint:(NSString*)entryName
{
    
    if( activeContext == nil || activeContext.module == nil)
        return nil;
    
    TCSyntaxNode * tree = activeContext.module;
    
    // Start by finding the location of the entrypoint in the tree we were given.
    if( tree.nodeType == LANGUAGE_MODULE) {
        for( int ix = 0; ix < tree.subNodes.count; ix++) {
            TCSyntaxNode* entry = tree.subNodes[ix];
            if( entry.nodeType != LANGUAGE_ENTRYPOINT)
                continue;
            if( [entry.spelling isEqualToString:entryName]) {
                return entry;
            }
        }
    }
    return nil;
    
}


-(TCFunction*) findBuiltin:(NSString*) name
{
    NSString * functionClassName = [NSString stringWithFormat:@"TC%@Function", name];
    
    TCFunction * f = [[NSClassFromString(functionClassName) alloc] init];
    return f;
}

-(BOOL) hasUnresolvedNames:(TCSyntaxNode*) node
{
    
    // If this is a CALL node, make sure the target is known as either
    // an internal function or a user-written function.
    
    if( node.nodeType == LANGUAGE_CALL) {
        
        TCSyntaxNode * entryNode = [self findEntryPoint:node.spelling];
        if( entryNode == nil ) {
            TCFunction * f = [self findBuiltin:node.spelling];
            if( f == nil ) {
                _error = [[TCError alloc]initWithCode:TCERROR_UNK_ENTRYPOINT
                                               atNode:node
                                         withArgument:node.spelling];
                return YES;
            }
        }
    }
    
    // Search any child nodes as well.
    
    for( int ix = 0; ix < node.subNodes.count; ix++ ) {
        if( [self hasUnresolvedNames:node.subNodes[ix]])
            return YES;
    }
    
    return NO;
}
@end
