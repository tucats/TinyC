//
//  ExpressionInterpreter.m
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import "TCExpressionInterpreter.h"
#import "TCToken.h"
#import "TCLexicalScanner.h"
#import "TCExpressionParser.h"
#import "TCSymbolTable.h"
#import "TCExecutionContext.h"
#import "NSString+NSStringFormatting.h"
#import "TCFunction.h"


char* typeMap(TCValueType);

extern TCExecutionContext* activeContext;

@implementation TCExpressionInterpreter

-(TCValue*) evaluateString:(NSString *)string
{
    TCLexicalScanner * parser = [[TCLexicalScanner alloc] initFromDefaultFile:@"LanguageTokens.plist"];
    
    // Lex the command text
    [parser lex:string];
    
    // Given a lexed string, parse an expression
    TCExpressionParser * exp = [[TCExpressionParser alloc]init];
    TCSyntaxNode * tree = [exp parse:parser];
    
    return [self evaluate:tree withSymbols:nil];
}


-(TCValue*) evaluate:(TCSyntaxNode *)node withSymbols:(TCSymbolTable*) symbols
{
    
    switch( node.nodeType) {
            
            // A pointer
            
        case LANGUAGE_ADDRESS:
        {
            TCValue *targetAddress = nil;
            TCSymbol * sym = nil;
            
            // IF this is a named address we want the shortcut of getting the address of this value
            // from the symbol table.
            
            if( node.spelling) {
                
                sym = [symbols findSymbol:node.spelling];
                
                if( sym == nil ) {
                    _error = [[TCError alloc]initWithCode:TCERROR_UNK_IDENTIFIER
                                                   atNode:node
                                             withArgument:node.spelling];
                    if( _debug )
                        NSLog(@"C_ERROR: %@", _error);
                    return nil;
                }
                if(!sym.allocated) {
                    NSLog(@"C_ERROR: attempt to write to unallocated variable %@", node.spelling);
                    return nil;
                }
                targetAddress = [[[TCValue alloc]initWithLong:sym.address] makePointer:sym.type];
                
            }
            
            // Not a named item, but an expression. Process the expression to get the result.
            else {
                TCSyntaxNode * targetExpr = (TCSyntaxNode*)node.subNodes[0];
                targetAddress = [self evaluate:targetExpr withSymbols:symbols];
                if( targetAddress.getType < TCVALUE_POINTER)
                    targetAddress = [targetAddress makePointer:targetAddress.getType];
            }
            
            if( _debug )
                NSLog(@"TRACE:   Locate address of %@, %@", node.spelling, targetAddress);
            
            return targetAddress;
            
            
        }
            
        case LANGUAGE_DEREFERENCE:
        {
            // Process the subnodes, which must result in a pointer.  Get the value
            // of the pointer.
            TCExpressionInterpreter *expInt = [[TCExpressionInterpreter alloc]init];
            expInt.storage = _storage;
            expInt.debug = _debug;
            expInt.context = _context;
            
            TCValue * address = [expInt evaluate:node.subNodes[0] withSymbols:symbols];
            if( address == nil ) {
                _error = expInt.error;
                return nil;
            }
            
            // @NODE need the base type of what we are dereferencing here!
            int baseType = TCVALUE_INT;
            
            return [_storage getValue:address.getLong ofType:baseType];
        }
            
            // An assignment operator?
        case LANGUAGE_ASSIGNMENT:
            return [activeContext execute:node withSymbols:symbols];
            
            // A function call?
        case LANGUAGE_CALL:
            return [self functionCall:node withSymbols:symbols];
            
            
            // If we are at the start of an expression, just dive in to
            // the next layer down. Note that an EXPRESSION can really
            // be a list of expressions.  We process all of them, but
            // only return the first one evaluated.  This is used to
            // support things like ++x and x-- which require two
            // expression components (the reference to the value and
            // the increment or decrement) and the order depends on
            // pre- or post-increment functionality.
            
        case LANGUAGE_EXPRESSION:
        {
            TCValue * result = nil;
            TCValue * subExpression = nil;
            
            for( int i = 0; i < node.subNodes.count; i++) {
                subExpression = [self evaluate:node.subNodes[i] withSymbols:symbols];
                if( i == 0 )
                    result = subExpression;
            }
            return result;
        }
            // A cast operation?
        case LANGUAGE_CAST:
        {
            // Process the source expression
            TCValue * result = [self evaluate:node.subNodes[1] withSymbols:symbols];
            
            // Cast to the target type.  NOTE THIS ONLY SUPPORTS SIMPLE TYPES
            // AT THIS POINT.  No user types allowed yet.
            TCSyntaxNode * castInfo = (TCSyntaxNode*)node.subNodes[0];
            
            if( _debug)
                NSLog(@"TRACE:   Cast %@ to type %s", result, typeMap(castInfo.action));
            result = [result castTo:castInfo.action];
            return result;
        }
    
            // An array reference
            
        case LANGUAGE_ARRAY:
        {
            // Find the symbolic name.  Fail if it doesn't exist
            TCSymbol * targetSymbol = [symbols findSymbol:node.spelling];
            if( targetSymbol == nil ){
                _error = [[TCError alloc]initWithCode:TCERROR_IDENTIFIERNF
                                               atNode:node
                                         withArgument:node.spelling];
                return nil;
            }
            
            // The offset is the stride (size of base type) times the index.  Get the
            // stride from the symbol table's declaration
            
            int stride = targetSymbol.size;
            if( targetSymbol.type > TCVALUE_POINTER) {
                stride = [TCValue sizeOf:targetSymbol.type];
            }
            
            // Calculate the index by executing the index expression
            
            TCValue * indexValue = [self evaluate:node.subNodes[0] withSymbols:symbols];
            
            // Calculate the resulting address, and make it into a pointer to the base type
            // of the appropriate address.
            
            long arrayBase = [_storage getLong:targetSymbol.address];
            long address = arrayBase + (stride * indexValue.getLong);
            TCValue * reference = [[TCValue alloc]initWithLong:address];
            return [reference makePointer:(targetSymbol.type - TCVALUE_POINTER)];
            
        }
            
            // A simple symbol reference
            
        case LANGUAGE_REFERENCE:
        {
            // There are two kinds of REFERENCE nodes.  One contains a direct reference to
            // a symbol value.  The other kind requires processing a sub-expression and then
            // calculating a new address using that expression
            
            TCSymbol * targetSymbol = [symbols findSymbol:node.spelling];
            if( targetSymbol == nil ){
                _error = [[TCError alloc]initWithCode:TCERROR_IDENTIFIERNF
                                               atNode:node
                                         withArgument:node.spelling];
                return nil;
            }
            
            // Do we have real storage now?
            if( _storage != nil ) {
                if(_debug)
                    NSLog(@"TRACE:   Reference load value of %@, at %ld", node.spelling, targetSymbol.address);
                
                return [_storage getValue:targetSymbol.address ofType:targetSymbol.type];
            }
            if(_debug)
                NSLog(@"TRACE:   Reference load of %@ has no storage, using embedded value %@",
                      targetSymbol.spelling, targetSymbol.initialValue);
            return targetSymbol.initialValue;
            
        }
            break;
            
            //  A constant value stored in the node spelling.
            
        case LANGUAGE_SCALAR:
        {
            switch( node.action) {
                case TOKEN_INTEGER:
                    if(_debug)
                        NSLog(@"TRACE:   Load integer %@", node.spelling);
                    return [[TCValue alloc]initWithInt:(int) [node.spelling integerValue]];
                    
                case TOKEN_DOUBLE:
                    if(_debug)
                        NSLog(@"TRACE:   Load double %@", node.spelling);
                    return [[TCValue alloc]initWithDouble:[node.spelling doubleValue]];
                    
                case TOKEN_STRING: {
                    // Do a little extra work here to handle escapes.
                    
                    NSString * escapedString = [node.spelling escapeString];
                    
                    if(_debug)
                        NSLog(@"TRACE:   Load string %@", escapedString);
                    return [[TCValue alloc] initWithString:escapedString];
                }
                    
                case TCVALUE_CHAR + TCVALUE_POINTER:
                {
                    NSNumber* pointerObject = (NSNumber*) node.argument;
                    
                    long virtualAddress = pointerObject.longValue;
                    if( virtualAddress < 0 || virtualAddress > _storage.current) {
                        NSLog(@"ERROR: load of char* constant from illegal address");
                        return nil;
                    }
                    char* stringPtr = (char*)( _storage.buffer + virtualAddress);
                    
                    NSString * cString = [NSString stringWithCString:stringPtr encoding:NSUTF8StringEncoding];
                    if(_debug)
                        NSLog(@"TRACE:   load string literal %@ from char* pointer %ld", cString, virtualAddress);
                    
                    return [[TCValue alloc]initWithString:cString];
                }
                    
                default:
                    _error = [[TCError alloc] initWithCode:TCERROR_INTERP_BAD_SCALAR
                              atNode:node
                                              withArgument:[NSNumber numberWithInt:node.action]];
                    return nil;
            }
        }
            
        case LANGUAGE_MONADIC:
        {
            
            TCValue * target = [self evaluate:node.subNodes[0] withSymbols:symbols];
            if(_debug)
                NSLog(@"TRACE:   Monadic action %d on %@", node.action, target);
            switch(node.action) {
                case TOKEN_SUBTRACT:
                    return [target negate];
                    
                case TOKEN_NOT:
                    return [target booleanNot];
                    
                default:
                    _error = [[TCError alloc] initWithCode:TCERROR_INTERP_UNIMP_MODADIC
                                                    atNode:node
                                              withArgument:[NSNumber numberWithInt:node.action]];
                    return nil;
            }
        }
        case LANGUAGE_DIADIC:
        {
            TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
            if( _error)
                return nil;
            TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
            if( _error)
                return nil;
            
            if( left == nil || right == nil) {
                _error = [[TCError alloc]initWithCode:TCERROR_UNINIT_VALUE
                                               atNode:node
                                         withArgument:nil];
                return nil;
            }
            
            if( _debug)
                NSLog(@"TRACE:   Diadic action %d on %@, %@", node.action, left, right);
            
            switch(node.action) {
                case TOKEN_PERCENT:
                    return [left moduloValue:right];
                case TOKEN_BOOLEAN_AND:
                    return [[TCValue alloc]initWithLong:([left getLong] && [right getLong])];
                case TOKEN_BOOLEAN_OR:
                    return [[TCValue alloc]initWithLong:([left getLong] || [right getLong])];
                case TOKEN_ADD :
                    return [left addValue:right];
                case TOKEN_ASTERISK:
                    return [left multiplyValue:right];
                case TOKEN_SUBTRACT:
                    return [left subtractValue:right];
                case TOKEN_DIVIDE:
                    return [left divideValue:right];
                default:
                    _error = [[TCError alloc] initWithCode:TCERROR_INTERP_UNIMP_DIADIC
                                                    atNode:node
                                              withArgument:[NSNumber numberWithInt:node.action]];
                    return nil;
            }
        }
        case LANGUAGE_RELATION:
            switch(node.action) {
                case TOKEN_GREATER:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithLong:[left compareToValue:right] > 0];
                }
                case TOKEN_GREATER_OR_EQUAL:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithLong:[left compareToValue:right] >= 0];
                }
                case TOKEN_LESS:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithLong:[left compareToValue:right] < 0];
                }
                case TOKEN_LESS_OR_EQUAL:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithLong:[left compareToValue:right] <= 0];
                }
                case TOKEN_EQUAL:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithLong:[left compareToValue:right] == 0];
                }
                case TOKEN_NOT_EQUAL:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithLong:[left compareToValue:right] != 0];
                }
                    
                default:
                    _error = [[TCError alloc] initWithCode:TCERROR_INTERP_UNIMP_RELATION
                                                    atNode:node
                                              withArgument:[NSNumber numberWithInt:node.action]];
                    
                    return nil;
            }
            
        default:
            _error = [[TCError alloc]initWithCode:TCERROR_INTERP_UNIMP_NODE
                                           atNode:node
                                     withArgument:[NSNumber numberWithInt:node.nodeType]];
            
            return nil;
    }
    
    
}

-(TCValue*) functionCall:(TCSyntaxNode *) node withSymbols:(TCSymbolTable*)symbols
{
    TCValue * result = nil;
    
    if( node == nil ) {
        _error = [[TCError alloc]initWithCode:TCERROR_FATAL
                                       atNode:node
                                 withArgument:@"Call to nil node"];
        return nil;
    }
    if( node.nodeType != LANGUAGE_CALL) {
        _error = [[TCError alloc]initWithCode:TCERROR_FATAL
                                       atNode:node
                                 withArgument:@"Call to wrong node type"];
        return nil;
    }
    
    if( _debug)
        NSLog(@"TRACE:   Attempt to call function %@", node.spelling);
    
    // Build an argument list array
    
    NSMutableArray * arguments = [NSMutableArray array];
    
    for( int ix = 0; ix < node.subNodes.count; ix++ ) {
        if(_debug)
            NSLog(@"TRACE:   Evaluate argument %d", ix);
        TCSyntaxNode * exp = (TCSyntaxNode*) node.subNodes[ix];
        TCValue * argValue = [self evaluate:exp withSymbols:symbols];
        [arguments addObject:argValue];
    }
    
    // Locate the entry point
    
    TCSyntaxNode * entry =[activeContext findEntryPoint:node.spelling];
    if( entry != nil) {
        if(_debug)
            NSLog(@"TRACE:   Found entry point at %@, creating new frame", entry);
        
        
        TCExecutionContext * savedContext = activeContext;
        TCExecutionContext * newContext = [[TCExecutionContext alloc]initWithStorage:self.storage];
        newContext.debug = activeContext.debug;
        
        activeContext = newContext;
        
        newContext.symbols = symbols;
        result = [newContext execute:entry entryPoint:nil withArguments:arguments];
        if(newContext.error)
            _error = newContext.error;
        
        activeContext = savedContext;
        newContext = nil;
        return result;
    }
    
    // See if it is a built-in function?
    
    return [self executeFunction:node.spelling withArguments:arguments atNode:node];
}

/**
 Try to execute a built-in function by name.  These are all subclasses of
 the TCFunction class, and are identified as TCxxxxFunction where "xxxx"
 is the name of the function. So printf() is TCprintfFunction, etc.
 
 @param name the name of the function to locate
 @param arguments the list of arguments expressed as TCValue items
 @return a TCValue if the function executed correctly.  If the function
 was not found or there was a runtime error, nil is returned.
 */

-(TCValue*) executeFunction:(NSString *)name withArguments:(NSArray *)arguments atNode:(TCSyntaxNode*)node
{
    
    // First, see if it is a known class we can dynamically construct an instance
    // of to execute
    
    TCFunction * f = [activeContext findBuiltin:name];
    
    if( f != nil ) {
        if(_debug)
            NSLog(@"TRACE:   dynamic execution of \"%@\" function", name);
        f.storage = _storage;
        TCValue * result = [f execute:arguments inContext:_context];
        _error = f.error;
        return result;
    }
    
    _error = [[TCError alloc]initWithCode:TCERROR_UNK_ENTRYPOINT
                                   atNode:node
                             withArgument:name];
    return nil;
    
}
@end


