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
#import "TCStatement.h"
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

-(TCSyntaxNode*) parse:(TCParser *)parser
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
    
    // NSLog(@"PARSE declaration");
    while(TRUE) {
        
        BOOL isPointer = NO;
        
        if( [parser isNextToken:TOKEN_ASTERISK])
            isPointer = YES;
        
        if(![parser isNextToken:TOKEN_IDENTIFIER]) {
            [parser error:TCERROR_IDENTIFIERNF];
            return nil;
        }
        
        varData = [[TCSyntaxNode alloc]init];
        varData.nodeType =  LANGUAGE_NAME;
        
        varData.action = isPointer ? TCVALUE_UNDEFINED : decl.action;
        varData.spelling = [parser lastSpelling];
        
        
        if([parser isNextToken:TOKEN_ASSIGNMENT]) {
            
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
        
        if(![parser isNextToken:TOKEN_COMMA])
            break;
    }
    
    return decl;
    
}
@end
