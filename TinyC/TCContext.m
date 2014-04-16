//
//  TCContext.m
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//

#import "TCContext.h"
#import "TCSyntaxNode.h"
#import "TCSymbolTable.h"
#import "TCError.h"
#import "TCValue.h"
#import "TCToken.h"
#import "TCExpressionInterpreter.h"

TCContext* activeContext;

#pragma mark - Utilities

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
            
        default:
            newType = (TCValueType)theType;
    }
    
    return [value castTo:newType];
}

@implementation TCContext

#pragma mark - Initialization

-(instancetype)initWithStorage:(TCStorage*) storage
{
    if(( self = [super init])) {
        _storage = storage;
    }
    
    return self;
}

#pragma mark - Execution

-(TCValue*)execute:(TCSyntaxNode *)tree withSymbols:(TCSymbolTable *)symbols
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
            NSLog(@"LANGPRC: Searching MODULE for entrypoint %@", entryName);
        
    }
    
    // If there is an entry name, we have work to do to find the entry point,
    // manage arguments, etc.  If there is no entry name, then this is just a
    // recursive call to execute a nested block, usually.
    
    if( entryName != nil ) {
        activeContext.module = tree;
        tree = [self findEntryPoint:entryName];
    }
    
    int dataType = 0;
    int ix = 0;
    // Execute a statement or a block.
    
    switch( tree.nodeType) {
            
            // Most common case, a call to a function with no result or an assignment
            
        case LANGUAGE_EXPRESSION:
        {
            TCExpressionInterpreter * expInt = [[TCExpressionInterpreter alloc]init];
            expInt.debug = _debug;
            expInt.storage = _storage;
            
            [expInt evaluate:tree withSymbols:_symbols];  // Note we don't care about result either
            if(expInt.error) {
                _error = expInt.error;
                return nil;
            }
        }
            break;
            
        case LANGUAGE_ENTRYPOINT:
            
        {
            if( _debug)
                NSLog(@"LANGPRC: Beginning execution of entrypoint %@", tree.spelling);
            
            
            // The first subnode is the return type; squirrel that away.
            
            self.returnInfo = tree.subNodes[0];
            
            // The next ones are the argument list; the count not be less
            // than number of arguments provided. Assign the values to the
            //local variable initializer field.
            
             if( arguments.count < (tree.subNodes.count - 2)) {
                _error = [[TCError alloc]initWithCode:TCERROR_ARG_MISMATCH withArgument:nil];
                return nil;
            }
            
            if( tree.subNodes.count > 2 ) {
                _importedArguments = [NSMutableArray array];
                for( int ix = 0; ix < arguments.count; ix++ ) {
                    TCSyntaxNode* localArg = tree.subNodes[ix+1];
                    TCSyntaxNode* localArgName = localArg.subNodes[0];
                    
                    // @NOTE : probably need to look at casting each argument to the type
                    // of the caller so we don't read storage values incorrectly!!
                    
                    TCValue* argValue = (TCValue*) arguments[ix];
                    if( argValue.getType != localArg.action) {
                        if( _debug)
                            NSLog(@"LANGPRC: Casting function parm #%d to %s", ix+1, typeMap(localArg.action));
                        argValue = [argValue castTo:localArg.action];
                    }
                    localArgName.argument = argValue;
                    [_importedArguments addObject:localArg ];
                    
                    if(_debug)
                        NSLog(@"LANGPRC: Add arg #%d %@ of type %s to arglist",ix, localArgName.spelling, typeMap(localArg.action));
                }
            }
            // The final subnode is the code block to execute. Fetch that out and let's run it.
            
            tree = tree.subNodes[tree.subNodes.count-1];
            return [self execute:tree];
            
        }
            
            // A group of statements executed sequentially
        case LANGUAGE_BLOCK:
        {
            
            // A block requires a new symbol context so symbols declared are local to the block
            
            TCSymbolTable * scopedSymbols = [[TCSymbolTable alloc]init];
            scopedSymbols.parent = self.symbols;
            self.symbols = scopedSymbols;
            self.error = nil;
            [_storage pushStorage];  // Make a new storage frame
            
            if( _importedArguments ) {
                if( _debug)
                    NSLog(@"LANGPRC: Importing %d arguments to local symbol table",
                          (int)_importedArguments.count);
                for( int ix = 0; ix < _importedArguments.count; ix ++ ) {
                    TCSyntaxNode * argDecl = (TCSyntaxNode*) _importedArguments[ix];
                    [self execute:argDecl];
                }
                _importedArguments = nil;
            }
            for( ix = 0; ix < tree.subNodes.count; ix++) {
                _blockPosition = ix;
                result = [self execute:tree.subNodes[ix] withSymbols:self.symbols];
                
                if( self.error.isBreak) {
                    break;
                }
                
                if( self.error.isReturn) {
                    return result;
                }
                
                if( self.error)
                    return nil;
            }
            
            // Now release the scoped block
            self.symbols = scopedSymbols.parent;
            scopedSymbols = nil;
            [_storage popStorage];
        }
            break;
            
        case LANGUAGE_ASSIGNMENT:
        {
            TCSyntaxNode * target = tree.subNodes[0];
            TCSyntaxNode * exp = tree.subNodes[1];
            TCExpressionInterpreter *expInt = [[TCExpressionInterpreter alloc]init];
            expInt.debug = _debug;
            expInt.storage = _storage;
            
            TCValue * value = [expInt evaluate:exp withSymbols:_symbols];
            if( expInt.error) {
                _error = expInt.error;
                return nil;
            }
            
            // Simple assignment. This needs to be expanded later to handle
            // targets other than simple ADDRESS
            TCSymbol * targetValue = [_symbols findSymbol:target.spelling];
            if( _debug )
                NSLog(@"LANGPRC: Assign %@ to %@", value, target.spelling);
            if( targetValue == nil ) {
                _error = [[TCError alloc]initWithCode:TCERROR_UNK_IDENTIFIER withArgument:target.spelling];
                if( _debug )
                    NSLog(@"C_ERROR: %@", _error);
                return nil;
            }
            if(!targetValue.allocated) {
                NSLog(@"C_ERROR: attempt to write to unallocated variable %@", targetValue);
            }
            value = [value castTo:targetValue.type];
            targetValue.initialValue = value;
            if( _storage) {
                [_storage setValue:value at:targetValue.address];
            }
            result = value;
        }
            break;
            
        case LANGUAGE_IF:
        {
            TCSyntaxNode * condition = tree.subNodes[0];
            TCSyntaxNode * ifTrue = tree.subNodes[1];
            
            TCExpressionInterpreter * expInt = [[TCExpressionInterpreter alloc]init];
            expInt.debug = _debug;
            
            TCValue * condValue = [expInt evaluate:condition withSymbols:_symbols];
            if( condValue.getLong ) {
                if(_debug)
                    NSLog(@"LANGPRC: Condition value %@, execute true branch", condValue);
                result = [self execute:ifTrue withSymbols:_symbols];
            } else if( tree.subNodes.count > 2) {
                if(_debug)
                    NSLog(@"LANGPRC: Condition value %@, execute false branch", condValue);
                result = [self execute:tree.subNodes[2] withSymbols:_symbols];
            } else if(_debug)
                NSLog(@"LANGPRC: Condition value %@, nothing executed", condValue);
        }
            break;
            
        case LANGUAGE_RETURN:
        {
            TCExpressionInterpreter * expInt = [[TCExpressionInterpreter alloc]init];
            expInt.debug = _debug;
            
            result = [expInt evaluate:tree.subNodes[0] withSymbols:_symbols];
            if( expInt.error) {
                _error = expInt.error;
                return nil;
            }
            if( _debug) {
                NSLog(@"LANGPRC: Returning block value %@", result);
            }
            
            if( _returnInfo ) {
                if(_debug) {
                    NSLog(@"LANGPRC: Return type coerced to %s", typeMap(_returnInfo.action));
                }
                result = coerceType(result, _returnInfo.action);
            }
            //[_storage popStorage];
            return result;
        }
            
        case LANGUAGE_DECLARE:
            
            dataType = tree.nodeAction;
            
            for( ix = 0; ix < tree.subNodes.count; ix++) {
                TCSyntaxNode * declaration = tree.subNodes[ix];
                if(_storage) {
                    _lastSymbol = [_symbols newSymbol:declaration.spelling ofType:declaration.action storage:_storage];
                }
                else
                    NSLog(@"FATAL ERROR - NO STORAGE AVAILABLE");
                if( declaration.argument && _storage)
                    [_lastSymbol setValue: (TCValue*)declaration.argument storage:_storage];
                else if( !_storage)
                    NSLog(@"C_ERROR: declaration initializer with no storage allocation");

                
                if( _debug) {
                    if( _lastSymbol.initialValue)
                        NSLog(@"LANGPRC: Created new variable %@ with initial value %@", _lastSymbol, _lastSymbol.initialValue);
                    else
                        NSLog(@"LANGPRC: Created new variable %@", _lastSymbol);
                }
            }
            
            break;
            
            
        default:
            self.error = [[TCError alloc]initWithCode:TCERROR_UNK_STATEMENT
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
@end
