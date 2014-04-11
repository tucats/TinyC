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

TCValue* coerceType(TCValue* value, TokenType theType)
{
    TCValueType newType;
    
    switch( theType) {
        case TOKEN_DECL_INT:
            newType = TCVALUE_INTEGER;
            break;
        case TOKEN_DECL_DOUBLE:
            newType = TCVALUE_DOUBLE;
            break;
        case TOKEN_DECL_FLOAT:
            newType = TCVALUE_FLOAT;
            break;
            
        default:
            newType = value.getType;
    }
    
    return [value castTo:newType];
}

@implementation TCContext

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
    
    TCValue * result = [[TCValue alloc]initWithInteger:0];
    self.block = nil;
    self.parent = nil;
    self.blockPosition = 0;
    self.error = nil;
    
    if(_debug) {
        if( entryName != nil)
            NSLog(@"Searching MODULE for entrypoint %@", entryName);
            
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
        
        case LANGUAGE_ENTRYPOINT:
            
        {
            if( _debug)
                NSLog(@"Beginning execution of entrypoint %@", tree.spelling);
            
            
            // The first subnode is the return type; squirrel that away.
            
            self.returnInfo = tree.subNodes[0];

            // The next ones are the argument list; the count must match and then we
            // assign the values to the local variable initializer field.
            
            if( arguments && (tree.subNodes.count == 2)) {
                _error = [[TCError alloc]initWithCode:TCERROR_ARG_MISMATCH withArgument:nil];
                return nil;
            }
            if( arguments.count != (tree.subNodes.count - 2)) {
                _error = [[TCError alloc]initWithCode:TCERROR_ARG_MISMATCH withArgument:nil];
                return nil;
            }
            
            if( arguments ) {
                _importedArguments = [NSMutableArray array];
                for( int ix = 0; ix < arguments.count; ix++ ) {
                    TCSyntaxNode* localArg = tree.subNodes[ix+1];
                    TCSyntaxNode* localArgName = localArg.subNodes[0];
                    localArgName.argument = (TCValue*) arguments[ix];
                    [_importedArguments addObject:localArg ];
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
            
            if( _importedArguments ) {
                if( _debug)
                    NSLog(@"Importing %d arguments to local symbol table",
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
        }
            break;
            
        case LANGUAGE_ASSIGNMENT:
        {
            TCSyntaxNode * target = tree.subNodes[0];
            TCSyntaxNode * exp = tree.subNodes[1];
            TCExpressionInterpreter *expInt = [[TCExpressionInterpreter alloc]init];
            TCValue * value = [expInt evaluate:exp withSymbols:_symbols];
            if( expInt.error) {
                _error = expInt.error;
                return nil;
            }
            
            // Simple assignment. This needs to be expanded later to handle
            // targets other than simple ADDRESS
            TCSymbol * targetValue = [_symbols findSymbol:target.spelling];
            if( _debug )
                NSLog(@"Assign %@ to %@", value, target.spelling);
            if( targetValue == nil ) {
                _error = [[TCError alloc]initWithCode:TCERROR_UNK_IDENTIFIER withArgument:target.spelling];
                if( _debug )
                    NSLog(@"%@", _error);
                return nil;
            }
            targetValue.initialValue = value;
        }
            break;
            
        case LANGUAGE_IF:
        {
            TCSyntaxNode * condition = tree.subNodes[0];
            TCSyntaxNode * ifTrue = tree.subNodes[1];
            
            TCExpressionInterpreter * expInt = [[TCExpressionInterpreter alloc]init];
            TCValue * condValue = [expInt evaluate:condition withSymbols:_symbols];
            if( condValue.getInteger ) {
                if(_debug)
                    NSLog(@"Condition value %@, execute true branch", condValue);
                result = [self execute:ifTrue withSymbols:_symbols];
            } else if( tree.subNodes.count > 2) {
                if(_debug)
                    NSLog(@"Condition value %@, execute false branch", condValue);
                result = [self execute:tree.subNodes[2] withSymbols:_symbols];
            } else if(_debug)
                NSLog(@"Condition value %@, nothing executed", condValue);
        }
            break;
            
        case LANGUAGE_RETURN:
        {
            TCExpressionInterpreter * expInt = [[TCExpressionInterpreter alloc]init];
            result = [expInt evaluate:tree.subNodes[0] withSymbols:_symbols];
            if( _debug) {
                NSLog(@"Returning block value %@", result);
            }
            
            if( _returnInfo ) {
                if( _debug ) {
                    NSLog(@"Return type should be coerced to %d", _returnInfo.action);
                }
                result = coerceType(result, _returnInfo.action);
            }
            
            return result;
        }
            
        case LANGUAGE_DECLARE:
            
            dataType = tree.nodeAction;
            
            for( ix = 0; ix < tree.subNodes.count; ix++) {
                TCSyntaxNode * declaration = tree.subNodes[ix];
                _lastSymbol = [[TCSymbol alloc]init];
                _lastSymbol.spelling = declaration.spelling;
                
                switch( declaration.action) {
                        
                    case TOKEN_DECL_INT:
                        _lastSymbol.type = TCVALUE_INTEGER;
                        _lastSymbol.size = sizeof(int);
                        break;
                        
                    case TOKEN_DECL_DOUBLE:
                        _lastSymbol.type = TCVALUE_DOUBLE;
                        _lastSymbol.size = sizeof(double);
                        break;
                        
                    case TOKEN_DECL_FLOAT:
                        _lastSymbol.type = TCVALUE_FLOAT;
                        _lastSymbol.size = sizeof(float);
                        break;
                        
                    case TOKEN_DECL_CHAR:
                        _lastSymbol.type = TCVALUE_STRING;
                        _lastSymbol.size = 1;
                        break;
                        
                    default:
                        _lastSymbol.type = TCVALUE_UNDEFINED;
                }
                _lastSymbol.allocated = YES;
                _lastSymbol.initialValue = (TCValue*)declaration.argument;
            
                [self.symbols.symbols setObject:_lastSymbol forKey:declaration.spelling];
                if( _debug) {
                    if( _lastSymbol.initialValue)
                        NSLog(@"Created new variable %@ with initial value %@", _lastSymbol, _lastSymbol.initialValue);
                    else
                        NSLog(@"Created new variable %@", _lastSymbol);
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
