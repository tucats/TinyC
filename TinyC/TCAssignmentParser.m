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

-(TCSyntaxNode*) parseLValue:(TCParser*)parser
{
    TCSyntaxNode * lvalue = [TCSyntaxNode node];

    // Right now all we know about is simple identifiers
    
    long savedPosition = parser.position;
    
    if( [parser isNextToken:TOKEN_IDENTIFIER]) {
        lvalue.nodeType = LANGUAGE_ADDRESS;
        lvalue.spelling = [parser lastSpelling];
        return lvalue;
    }
    // No lvalue found, reset the parse position
    
    [parser setPosition:savedPosition];
    return nil;
}


-(TCSyntaxNode*) parse:(TCParser *)parser
{
    TCSyntaxNode * stmt = [[TCSyntaxNode alloc] init];
    stmt.nodeType = LANGUAGE_ASSIGNMENT;
    
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
