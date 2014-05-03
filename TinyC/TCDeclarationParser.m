//
//  TCDeclarationParser.m
//  Language
//
//  Created by Tom Cole on 4/5/14.
//
//

#import "TCDeclarationParser.h"
#import "TCExpressionParser.h"
#import "TCExpressionInterpreter.h"
#import "TCStatementParser.h"
#import "TCToken.h"
#import "TCTypeParser.h"
#import "TCSyntaxNode.h"

TCValueType tokenToType( TokenType tok )
{
    
    switch( tok ) {
        case TOKEN_DECL_CHAR:
            return TCVALUE_CHAR;
        case TOKEN_DECL_INT:
            return TCVALUE_INT;
        case TOKEN_DECL_LONG:
            return TCVALUE_LONG;
        case TOKEN_DECL_FLOAT:
            return TCVALUE_FLOAT;
        case TOKEN_DECL_DOUBLE:
            return TCVALUE_DOUBLE;
        case TOKEN_DECL_POINTER:
            return TCVALUE_UNDEFINED;
            
        default:
            NSLog(@"FATAL - attempt to map unresolvable token type %d", tok);
            return -1;
    }
}


@implementation TCDeclarationParser


-(TCSyntaxNode*) parseSingle:(TCSymtanticParser *)parser
{
    _endOnComma = YES;
    TCSyntaxNode *tree = [self parse:parser];
    _endOnComma = NO;
    return tree;
}

-(TCSyntaxNode*) parse:(TCSymtanticParser *)parser
{
    TCSyntaxNode * decl = nil;
    parser.error = nil;
    TCSyntaxNode* varData = nil;
    
    // Is there a leading type definition here?
    
    TCTypeParser * typeData = [[TCTypeParser alloc]init];
    decl = [typeData parse:parser];
    if( decl == nil)
        return nil;
    
    // A declaration can be followed by a list of values of that
    // type.
    
    decl.nodeType = LANGUAGE_DECLARE;
    decl.position = parser.tokenPosition;
    
    // Note that if we already think this is a pointer type, we parsed
    // the "*" as part of the type itself.  If so, we need to back up
    // a position in the tree and let the "*" be parsed by the declartion
    // list of items.
    
    if( decl.subNodes[0]) {
        TCSyntaxNode * addrNode = (TCSyntaxNode*) decl.subNodes[0];
        if( addrNode && addrNode.nodeType == LANGUAGE_ADDRESS && parser.lastTokenType == TOKEN_ASTERISK) {
            [decl.subNodes removeObjectAtIndex:0];
            addrNode = nil;
            parser.position = parser.position - 1;
        }
    }
    // NSLog(@"PARSE declaration");
    while(TRUE) {
        
        BOOL isPointer = NO;
        
        if( [parser isNextToken:TOKEN_ASTERISK])
            isPointer = YES;
        
        if(![parser isNextToken:TOKEN_IDENTIFIER]) {
            [parser error:TCERROR_IDENTIFIERNF];
            return nil;
        }
        
        varData = [TCSyntaxNode node:LANGUAGE_NAME];
        varData.position = parser.tokenPosition;
        
        varData.action = isPointer ? decl.action + TCVALUE_POINTER : decl.action;
        varData.spelling = [parser lastSpelling];
        
        // See if this is an array declaration. This would be followed by
        // "[", expression, "]".  In this case, we convert the type to a
        // pointer, but preallocate the space it points to based on the
        // array size.
        
        if([parser isNextToken:TOKEN_BRACKET_LEFT]) {
            
            // We need an initializer here, which can be parsed
            // as a constant literal.
            
            TCExpressionParser * initExpression = [[TCExpressionParser alloc]init];
            TCSyntaxNode * expression = [initExpression parse:parser];
            if( expression == nil)
                return nil;
            TCExpressionInterpreter * initInterp = [[TCExpressionInterpreter alloc]init];
            TCValue * initValue = [initInterp evaluate:expression withSymbols:nil];
            if( initValue == nil)
                return nil;
            
            long arraySize = initValue.getLong;
            // Generate a tree containing a call to _array with the right size.
            // Create two arguments, the size and the type code to pass as
            // parameters.
            
            TCSyntaxNode * allocator = [TCSyntaxNode node:LANGUAGE_CALL];
            allocator.spelling  = @"_array";
            TCSyntaxNode * arg1 = [TCSyntaxNode node:LANGUAGE_SCALAR];
            arg1.action = TOKEN_INTEGER;
            arg1.spelling = [NSString stringWithFormat:@"%ld", arraySize];
            TCSyntaxNode * arg2 = [TCSyntaxNode node:LANGUAGE_SCALAR];
            arg2.action = TOKEN_INTEGER;
            arg2.spelling = [NSString stringWithFormat:@"%d", decl.action];
            allocator.subNodes = [NSMutableArray arrayWithArray:@[arg1, arg2]];
            varData.action = decl.action + TCVALUE_POINTER;
            varData.subNodes = [NSMutableArray arrayWithArray: @[allocator]];
            
            if(![parser isNextToken:TOKEN_BRACKET_RIGHT]) {
                parser.error = [[TCError alloc]initWithCode:TCERROR_BRACKETMISMATCH withArgument:nil];
                return nil;
            }
            
        }
        else if([parser isNextToken:TOKEN_ASSIGNMENT]) {
            
            // We need an initializer here, which can be parsed
            // as a constant literal string.
            
            TCExpressionParser * initExpression = [[TCExpressionParser alloc]init];
            TCSyntaxNode * expression = [initExpression parse:parser];
            if( expression == nil)
                return nil;
            TCExpressionInterpreter * initInterp = [[TCExpressionInterpreter alloc]init];
            TCValue * initValue = [initInterp evaluate:expression withSymbols:nil];
            if( initValue == nil)
                return nil;
            varData.argument = initValue;
        }
        if( decl.subNodes == nil) {
            decl.subNodes = [[NSMutableArray alloc]init];
        }
        
        if( varData != nil )
            [decl.subNodes addObject:varData];
        
        if(_endOnComma || ![parser isNextToken:TOKEN_COMMA])
            break;
    }
    
    return decl;
    
}
@end
