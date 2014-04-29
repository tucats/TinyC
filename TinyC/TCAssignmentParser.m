//
//  TCAssignmentParser.m
//  Language
//
//  Created by Tom Cole on 4/7/14.
//
//

#import "TCAssignmentParser.h"
#import "TCExpressionParser.h"

@implementation TCAssignmentParser

-(TCSyntaxNode*) parseLValue:(TCSymtanticParser*)parser
{

    // Right now all we know about is simple identifiers
    
    long savedPosition = parser.position;
    
    // Is there a dereference prefix?
    
    BOOL dereference = NO;
    if([parser isNextToken:TOKEN_ASTERISK])
        dereference = YES;
    
    if( [parser isNextToken:TOKEN_IDENTIFIER]) {
        TCSyntaxNode * lvalue = [TCSyntaxNode node:LANGUAGE_ADDRESS];
        lvalue.spelling = [parser lastSpelling];
        lvalue.position = parser.tokenPosition;
        
        // See if it is an array reference
        if([parser isNextToken:TOKEN_BRACKET_LEFT]) {
            TCExpressionParser * expParser = [[TCExpressionParser alloc]init];
            TCSyntaxNode * arrayExpression = [expParser parse:parser];
            if( parser.error) {
                [parser setPosition:savedPosition];
                return nil;
            }
            if( arrayExpression == nil)
                return nil;
            if(![parser isNextToken:TOKEN_BRACKET_RIGHT]) {
                parser.error = [[TCError alloc]initWithCode:TCERROR_BRACEMISMATCH withArgument:nil];
                return nil;
            }
            lvalue.nodeType = LANGUAGE_ARRAY;
            lvalue.subNodes = [NSMutableArray arrayWithArray:@[arrayExpression]];
        }
        
        // Was it a pointer dereference?
        if(dereference) {
            TCSyntaxNode * deref = [TCSyntaxNode node:LANGUAGE_DEREFERENCE];
            deref.subNodes = [NSMutableArray arrayWithArray:@[lvalue]];
            return deref;
        }
        return lvalue;
    }
    // No lvalue found, reset the parse position
    
    [parser setPosition:savedPosition];
    return nil;
}


-(TCSyntaxNode*) parse:(TCSymtanticParser *)parser
{
    TCSyntaxNode * stmt = [TCSyntaxNode node:LANGUAGE_ASSIGNMENT];
    stmt.position = parser.tokenPosition;
    
    long savedPosition = parser.position;
    
    TCSyntaxNode * lvalue = [self parseLValue:parser];
    if( lvalue != nil ) {
        // Found an lvalue, do we have an assignment operator?
        
        if( [parser isNextToken:TOKEN_ASSIGNMENT]) {
            //NSLog(@"PARSE parse assignment");

            TCExpressionParser * expr = [[TCExpressionParser alloc] init];
            TCSyntaxNode *rvalue = [expr parse:parser];
            if( rvalue != nil ) {
                stmt.subNodes = [NSMutableArray arrayWithArray: @[lvalue, rvalue]];
                return stmt;
            }
        }
    }
    // No assignment found, reset to the start of where we poked around
    // so the next statement type can try.
    
    [parser setPosition:savedPosition];
    
    return nil;
}
@end
