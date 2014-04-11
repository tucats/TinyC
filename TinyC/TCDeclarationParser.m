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

@implementation TCDeclarationParser

-(TCSyntaxNode*) parse:(TCParser *)parser
{
    TCSyntaxNode * decl = nil;
    parser.error = nil;
    TCSyntaxNode* varData = nil;
    
    if( [parser isNextToken:TOKEN_DECL_INT]) {
        decl = [[TCSyntaxNode alloc]init];
        decl.nodeType = LANGUAGE_DECLARE;
        decl.action = TOKEN_DECL_INT;
        // NSLog(@"PARSE declaration");
        while(TRUE) {
            
            BOOL isPointer = NO;
            
            if( [parser isNextToken:TOKEN_MULTIPLY])
                isPointer = YES;
            
            if(![parser isNextToken:TOKEN_IDENTIFIER]) {
                [parser error:TCERROR_IDENTIFIERNF];
                return nil;
            }
            
            varData = [[TCSyntaxNode alloc]init];
            varData.nodeType =  LANGUAGE_NAME;
            
            varData.action = isPointer ? TOKEN_DECL_POINTER : TOKEN_DECL_INT;
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
    }
    
    // If we are here and the next token is "(" and we have only a single
    // declaration with no initializer, this is really a function definition
    // so fix it up.
    
    if( decl.subNodes.count == 1 && [parser isNextToken:TOKEN_PAREN_LEFT]) {
        
        decl.nodeType = LANGUAGE_ENTRYPOINT;
        decl.spelling = varData.spelling;
        varData.nodeType = LANGUAGE_RETURN_TYPE;
        
        // There are zero or more arguments which look like type definitions
        
        BOOL requireComma = NO;
        while(YES) {
            if([parser isNextToken:TOKEN_PAREN_RIGHT]) {
                break;
            }
            if( requireComma && ![parser isNextToken:TOKEN_COMMA]) {
                parser.error = [[TCError alloc]initWithCode:TCERROR_EXP_COMMA withArgument:nil];
                return nil;
            }
            TCSyntaxNode * arg = [self parse:parser];
            if( parser.error) {
                return nil;
            }
            if( arg == nil || arg.nodeType != LANGUAGE_DECLARE){
                parser.error = [[TCError alloc]initWithCode:TCERROR_EXP_DECLARATION withArgument:nil];
                return nil;
            }
            [decl.subNodes addObject:arg];
            
            // Later, handle var-args here
            
            requireComma = YES;
        }
        
        // Now, need body of function
        
        TCStatement * block = [[TCStatement alloc]init];
        TCError *error = nil;
        
        TCSyntaxNode * blockTree = [block parse:parser error:&error];
        if( !blockTree || parser.error) {
            return nil;
        }
        
        [decl.subNodes addObject:blockTree];
        
    }
    return decl;
    
}
@end
