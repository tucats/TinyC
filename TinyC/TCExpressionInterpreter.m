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
            
            // A simple symbol reference
            
        case LANGUAGE_REFERENCE:
        {
            if(_debug)
                NSLog(@"Locate reference to %@", node.spelling);
            
            TCSymbol * targetSymbol = [symbols findSymbol:node.spelling];
            if( targetSymbol == nil ){
                _error = [[TCError alloc]initWithCode:TCERROR_IDENTIFIERNF withArgument:node.spelling];
                return nil;
            }
            return targetSymbol.initialValue;
            
        }
            break;
            
            //  A constant value stored in the node spelling.
            
        case LANGUAGE_SCALAR:
        {
            if(_debug)
                NSLog(@"SCALAR action %d", node.action);
            
            switch( node.action) {
                case TOKEN_INTEGER:
                    return [[TCValue alloc]initWithInteger:[node.spelling integerValue]];
                    
                case TOKEN_DOUBLE:
                    return [[TCValue alloc]initWithDouble:[node.spelling doubleValue]];
                    
                case TOKEN_STRING:
                    return [[TCValue alloc]initWithString:node.spelling];
                    
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
                NSLog(@"Monadic action %d on %@", node.action, target);
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
                NSLog(@"Diadic action %d on %@, %@", node.action, left, right);
            
            switch(node.action) {
                case TOKEN_BOOLEAN_AND:
                    return [[TCValue alloc]initWithInteger:([left getInteger] && [right getInteger])];
                case TOKEN_BOOLEAN_OR:
                    return [[TCValue alloc]initWithInteger:([left getInteger] || [right getInteger])];
                case TOKEN_ADD :
                    return [left addValue:right];
                case TOKEN_MULTIPLY:
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
                    
                    return [[TCValue alloc]initWithInteger:[left compareToValue:right] > 0];
                }
                case TOKEN_GREATER_OR_EQUAL:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithInteger:[left compareToValue:right] >= 0];
                }
                case TOKEN_LESS:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithInteger:[left compareToValue:right] < 0];
                }
                case TOKEN_LESS_OR_EQUAL:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithInteger:[left compareToValue:right] <= 0];
                }
                case TOKEN_EQUAL:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithInteger:[left compareToValue:right] == 0];
                }
                case TOKEN_NOT_EQUAL:
                {
                    TCValue * left = [self evaluate:node.subNodes[0] withSymbols:symbols];
                    TCValue * right = [self evaluate:node.subNodes[1] withSymbols:symbols];
                    
                    return [[TCValue alloc]initWithInteger:[left compareToValue:right] != 0];
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
        NSLog(@"Attempt to call function %@", node.spelling);
    
    // Build an argument list array
    
    NSMutableArray * arguments = [NSMutableArray array];
    
    for( int ix = 0; ix < node.subNodes.count; ix++ ) {
        TCSyntaxNode * exp = (TCSyntaxNode*) node.subNodes[ix];
        TCValue * argValue = [self evaluate:exp withSymbols:symbols];
        [arguments addObject:argValue];
    }
    
    // Locate the entry point
    
    TCSyntaxNode * entry =[activeContext findEntryPoint:node.spelling];
    if( entry != nil) {
        if(_debug)
            NSLog(@"Found entry point at %@", entry);
        TCContext * newContext = [[TCContext alloc]init];
        newContext.symbols = symbols;
        result = [newContext execute:entry entryPoint:nil withArguments:arguments];
        if(newContext.error)
            _error = newContext.error;
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
            return [[TCValue alloc]initWithInteger:0];
        }
        NSMutableArray * valueArgs = [NSMutableArray array];
        TCValue* formatValue = (TCValue*) arguments[0];
        NSString * formatString = [formatValue getString];
        
        for( int i = 1; i < arguments.count; i++ ) {
            TCValue * x = (TCValue*) arguments[i];
            
            if( x.getType == TCVALUE_BOOLEAN)
                [valueArgs addObject:[NSNumber numberWithBool:x.getInteger]];
            if( x.getType == TCVALUE_INTEGER)
                [valueArgs addObject:[NSNumber numberWithLong:x.getInteger]];
            if( x.getType == TCVALUE_DOUBLE)
                [valueArgs addObject:[NSNumber numberWithDouble:x.getDouble]];
            
        }
        NSString * buffer = [NSString stringWithFormat:formatString array:valueArgs];
        
        printf([buffer UTF8String]);
        // NSLog(@"%@", buffer);
        return [[TCValue alloc]initWithInteger: arguments.count];
    }
    
    // not found!
    _error = [[TCError alloc]initWithCode:TCERROR_UNK_ENTRYPOINT withArgument:name];
    return nil;

}
@end


