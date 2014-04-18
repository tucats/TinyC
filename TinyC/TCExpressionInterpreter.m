//
//  ExpressionInterpreter.m
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import "TCExpressionInterpreter.h"
#import "TCToken.h"
#import "TCParser.h"
#import "TCExpressionParser.h"
#import "TCSymbolTable.h"
#import "TCContext.h"
#import "NSString+NSStringFormatting.h"

char* typeMap(TCValueType);

extern TCContext* activeContext;

@implementation TCExpressionInterpreter

-(TCValue*) evaluateString:(NSString *)string
{
    TCParser * parser = [[TCParser alloc] initFromDefaultFile:@"LanguageTokens.plist"];
    
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
                    _error = [[TCError alloc]initWithCode:TCERROR_UNK_IDENTIFIER withArgument:node.spelling];
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
                NSLog(@"EXPRESS: Locate address of %@, %@", node.spelling, targetAddress);
            
            return targetAddress;
            
            
        }
            // An assignment operator?
        case LANGUAGE_ASSIGNMENT:
            return [activeContext execute:node withSymbols:symbols];
            
            // A function call?
        case LANGUAGE_CALL:
            return [self functionCall:node withSymbols:symbols];
            
            
            // If we are at the start of an expression, just dive in to
            // the next layer down.
            
        case LANGUAGE_EXPRESSION:
            return [self evaluate:node.subNodes[0] withSymbols:symbols];
            
            // A cast operation?
        case LANGUAGE_CAST:
        {
            // Process the source expression
            TCValue * result = [self evaluate:node.subNodes[1] withSymbols:symbols];
            
            // Cast to the target type.  NOTE THIS ONLY SUPPORTS SIMPLE TYPES
            // AT THIS POINT.  No user types allowed yet.
            TCSyntaxNode * castInfo = (TCSyntaxNode*)node.subNodes[0];
            
            if( _debug)
                NSLog(@"EXPRESS: Cast %@ to type %s", result, typeMap(castInfo.action));
            result = [result castTo:castInfo.action];
            return result;
        }
            
            
            // A simple symbol reference
            
        case LANGUAGE_REFERENCE:
        {
            // There are two kinds of REFERENCE nodes.  One contains a direct reference to
            // a symbol value.  The other kind requires processing a sub-expression and then
            // calculating a new address using that expression
            
            TCSymbol * targetSymbol = [symbols findSymbol:node.spelling];
            if( targetSymbol == nil ){
                _error = [[TCError alloc]initWithCode:TCERROR_IDENTIFIERNF withArgument:node.spelling];
                return nil;
            }
            
            // Do we have real storage now?
            if( _storage != nil ) {
                if(_debug)
                    NSLog(@"EXPRESS: Reference load value of %@, at %ld", node.spelling, targetSymbol.address);
                
                return [_storage getValue:targetSymbol.address ofType:targetSymbol.type];
            }
            if(_debug)
                NSLog(@"EXPRESS: Reference load of %@ has no storage, using embedded value %@",
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
                        NSLog(@"EXPRESS: Load integer %@", node.spelling);
                    return [[TCValue alloc]initWithInt:(int) [node.spelling integerValue]];
                    
                case TOKEN_DOUBLE:
                    if(_debug)
                        NSLog(@"EXPRESS: Load double %@", node.spelling);
                    return [[TCValue alloc]initWithDouble:[node.spelling doubleValue]];
                    
                case TOKEN_STRING: {
                    // Do a little extra work here to handle escapes.
                    
                    NSString * escapedString = [node.spelling escapeString];
                    
                    if(_debug)
                        NSLog(@"EXPRESS: Load string %@", escapedString);
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
                        NSLog(@"EXPRESS: load string literal %@ from char* pointer %ld", cString, virtualAddress);
                    
                    return [[TCValue alloc]initWithString:cString];
                }
                    
                default:
                    _error = [[TCError alloc] initWithCode:TCERROR_INTERP_BAD_SCALAR
                                              withArgument:[NSNumber numberWithInt:node.action]];
                    return nil;
            }
        }
            
        case LANGUAGE_MONADIC:
        {
            
            TCValue * target = [self evaluate:node.subNodes[0] withSymbols:symbols];
            if(_debug)
                NSLog(@"EXPRESS: Monadic action %d on %@", node.action, target);
            switch(node.action) {
                case TOKEN_SUBTRACT:
                    return [target negate];
                    
                case TOKEN_NOT:
                    return [target booleanNot];
                    
                default:
                    _error = [[TCError alloc] initWithCode:TCERROR_INTERP_UNIMP_MODADIC
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
                _error = [[TCError alloc]initWithCode:TCERROR_UNINIT_VALUE withArgument:nil];
                return nil;
            }
            
            if( _debug)
                NSLog(@"EXPRESS: Diadic action %d on %@, %@", node.action, left, right);
            
            switch(node.action) {
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
                                              withArgument:[NSNumber numberWithInt:node.action]];
                    
                    return nil;
            }
            
        default:
            _error = [[TCError alloc]initWithCode:TCERROR_INTERP_UNIMP_NODE withArgument:[NSNumber numberWithInt:node.nodeType]];
            
            return nil;
    }
    
    
}

-(TCValue*) functionCall:(TCSyntaxNode *) node withSymbols:(TCSymbolTable*)symbols
{
    TCValue * result = nil;
    
    if( node == nil ) {
        _error = [[TCError alloc]initWithCode:TCERROR_FATAL withArgument:@"Call to nil node"];
        return nil;
    }
    if( node.nodeType != LANGUAGE_CALL) {
        _error = [[TCError alloc]initWithCode:TCERROR_FATAL withArgument:@"Call to wrong node type"];
        return nil;
    }
    
    
    if( _debug)
        NSLog(@"EXPRESS: Attempt to call function %@", node.spelling);
    
    // Build an argument list array
    
    NSMutableArray * arguments = [NSMutableArray array];
    
    for( int ix = 0; ix < node.subNodes.count; ix++ ) {
        if(_debug)
            NSLog(@"EXPRESS: Evaluate argument %d", ix);
        TCSyntaxNode * exp = (TCSyntaxNode*) node.subNodes[ix];
        TCValue * argValue = [self evaluate:exp withSymbols:symbols];
        [arguments addObject:argValue];
    }
    
    // Locate the entry point
    
    TCSyntaxNode * entry =[activeContext findEntryPoint:node.spelling];
    if( entry != nil) {
        if(_debug)
            NSLog(@"EXPRESS: Found entry point at %@, creating new frame", entry);
        
        
        TCContext * savedContext = activeContext;
        TCContext * newContext = [[TCContext alloc]initWithStorage:self.storage];
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
    
    return [self executeFunction:node.spelling withArguments:arguments];
}

-(TCValue*) executeFunction:(NSString *)name withArguments:(NSArray *)arguments
{
    
    if( [name isEqualToString:@"printf"]){
        
        // Simplest case, no arguments and we have no work.
        
        if( arguments == nil || arguments.count == 0 ) {
            _error = nil;
            return [[TCValue alloc]initWithLong:0];
        }
        NSMutableArray * valueArgs = [NSMutableArray array];
        TCValue* formatValue = (TCValue*) arguments[0];
        NSString * formatString = [formatValue getString];
        
        for( int i = 1; i < arguments.count; i++ ) {
            TCValue * x = (TCValue*) arguments[i];
            if( x.getType == TCVALUE_CHAR + TCVALUE_POINTER) {
                [valueArgs addObject:[_storage getString:x.getLong]];
            } else if( x.getType == TCVALUE_STRING)
                [valueArgs addObject:x.getString];
            else if( x.getType == TCVALUE_BOOLEAN)
                [valueArgs addObject:[NSNumber numberWithBool:x.getLong]];
            else if( x.getType == TCVALUE_INT)
                [valueArgs addObject:[NSNumber numberWithLong:x.getLong]];
            else if( x.getType == TCVALUE_LONG)
                [valueArgs addObject:[NSNumber numberWithLong:x.getLong]];
            else if( x.getType == TCVALUE_DOUBLE)
                [valueArgs addObject:[NSNumber numberWithDouble:x.getDouble]];
            else if( x.getType >= TCVALUE_POINTER)
                [valueArgs addObject:[NSNumber numberWithLong:x.getLong]];
            else {
                NSLog(@"ERROR: unusable argument type %d cannot be added to arglist ", x.getType);
                
            }
        }
        NSString * buffer = [[NSString stringWithFormat:formatString array:valueArgs] escapeString];
        //NSString *newString = [buffer stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        
        int bytesPrinted = printf("%s", [buffer UTF8String]);
        return [[TCValue alloc]initWithInt: bytesPrinted];
    }
    
    // not found!
    _error = [[TCError alloc]initWithCode:TCERROR_UNK_ENTRYPOINT withArgument:name];
    return nil;
    
}
@end


