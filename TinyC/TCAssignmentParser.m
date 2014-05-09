//
//  TCAssignmentParser.m
//  Language
//
//  Created by Tom Cole on 4/7/14.
//
//  Parse a basic assignment operation and create a tree
//
//                 LANGUAGE_ASSIGNMENT
//                          |
//                  +-------+------------+
//                  |                    |
//           LANGUAGE_ADDRESS    LANGUAGE_EXPRESSION
//              <target>              <source>
//
//  Notes:
//
//  1.  The target can be a named item's address, or it can be
//      a pointer dereference or an array reference.  An array
//      reference can contain arbitrary subexpressions to
//      calculate the index, including assignments.
//
//  2.  The source is any expression, which can contain sub
//      expressions including assignments.
//

#import "TCAssignmentParser.h"
#import "TCExpressionParser.h"

@implementation TCAssignmentParser


/**
 Parse an lvalue (the target of an assignment) from 
 the input stream
 and return a tree describing the operation
 if one is found.
 
 @param parser the parser that feeds lexical tokens to us
 @return a syntax tree describing the lvalue,
 or nil if no lvalue clause can be parsed
 */
-(TCSyntaxNode*) parseLValue:(TCLexicalScanner*)parser
{

    // Mark our spot in the input stream in case we have to
    // give up and report no lvalue here... the parser can be
    // reset to give a different parser a chance at the stream.
    
    long savedPosition = parser.position;
    
    // Is there a dereference prefix?
    
    BOOL dereference = NO;
    if([parser isNextToken:TOKEN_ASTERISK])
        dereference = YES;
    
    // Right now all we know about is simple identifiers
    if( [parser isNextToken:TOKEN_IDENTIFIER]) {
        
        // Start by creating an ADDRESS node that will calculate a
        // writable address of a value.
        TCSyntaxNode * lvalue = [TCSyntaxNode node:LANGUAGE_ADDRESS usingScanner:parser];
        lvalue.spelling = [parser lastSpelling];
        lvalue.position = parser.tokenPosition;
        
        // See if it is an array reference
        if([parser isNextToken:TOKEN_BRACKET_LEFT]) {
            
            // Parse the array index expression using the expression parser.
            // if we get an error, reset the parser position and report that
            // no lvalue was found.
            TCExpressionParser * expParser = [[TCExpressionParser alloc]init];
            TCSyntaxNode * arrayExpression = [expParser parse:parser];
            if( parser.error) {
                [parser setPosition:savedPosition];
                return nil;
            }
            if( arrayExpression == nil)
                return nil;
            
            // There has to be a closing bracket after the index expression
            if(![parser isNextToken:TOKEN_BRACKET_RIGHT]) {
                parser.error = [[TCError alloc]initWithCode:TCERROR_BRACEMISMATCH usingScanner:parser];
                return nil;
            }
            
            // Change the node type we are returning from a simple address
            // to an array reference, which has a subnode that is the index
            // expression.
            //
            // @NOTE Later when multidimensional arrays are supported
            // this can be a list of index expressions.
            lvalue.nodeType = LANGUAGE_ARRAY;
            lvalue.subNodes = [NSMutableArray arrayWithArray:@[arrayExpression]];
        }
        
        // Was it a pointer dereference of the simple identifier.  If so, then
        // change what we return to be a DEREFERENCE with the ADDRESS node we
        // previously worked out as it's sole child node.
        if(dereference) {
            TCSyntaxNode * deref = [TCSyntaxNode node:LANGUAGE_DEREFERENCE usingScanner:parser];
            deref.subNodes = [NSMutableArray arrayWithArray:@[lvalue]];
            return deref;
        }
        
        // It wasn't a dereference, so return what we worked out so far which
        // is either a value address or an array reference
        return lvalue;
    }
    
    
    // No lvalue found, reset the parse position and report nothing
    [parser setPosition:savedPosition];
    return nil;
}


/**
 Parse an assignment statement from the input stream
 and return a tree describing the assignment operation
 if one is found.
 
 @param parser the parser that feeds lexical tokens to us
 @return a syntax tree describing the assignment operation,
 or nil if no assignment statement can be parsed
 */

-(TCSyntaxNode*) parse:(TCLexicalScanner *)scanner
{
    TCSyntaxNode * stmt = [TCSyntaxNode node:LANGUAGE_ASSIGNMENT usingScanner:scanner];
    stmt.position = scanner.tokenPosition;
    
    long savedPosition = scanner.position;
    
    TCSyntaxNode * lvalue = [self parseLValue:scanner];
    if( lvalue != nil ) {
        // Found an lvalue, do we have an assignment operator?
        
        if( [scanner isNextToken:TOKEN_ASSIGNMENT]) {
            //NSLog(@"PARSE parse assignment");

            TCExpressionParser * expr = [[TCExpressionParser alloc] init];
            TCSyntaxNode *rvalue = [expr parse:scanner];
            if( rvalue != nil ) {
                stmt.subNodes = [NSMutableArray arrayWithArray: @[lvalue, rvalue]];
                return stmt;
            }
        }
    }
    // No assignment found, reset to the start of where we poked around
    // so the next statement type can try.
    
    [scanner setPosition:savedPosition];
    
    return nil;
}
@end
