//
//  ExpressionParser.m
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import "TCExpressionParser.h"

@implementation TCExpressionParser

- (TCSyntaxNode*)parseIdentifier:(TCParser *)parser
{
    TCSyntaxNode *atom = [[TCSyntaxNode alloc]init];
    atom.nodeType = LANGUAGE_REFERENCE;
    atom.spelling = [parser lastSpelling];
    
    // Let's check for cases other than the simplest reference
    // to a variable.
    
    // Is it a function?
    
    if( [parser isNextToken:TOKEN_PAREN_LEFT]) {
    
        atom.nodeType = LANGUAGE_CALL;
        // Parse argument list
        BOOL requireComma = NO;
        
        while(YES) {
            if([parser isNextToken:TOKEN_PAREN_RIGHT])
                break;
            
            if( requireComma) {
                if(![parser isNextToken:TOKEN_COMMA]) {
                    _error = [[TCError alloc]initWithCode:TCERROR_EXP_COMMA withArgument:nil];
                    return nil;
                }
            }
            TCSyntaxNode * argExpression = [self parse:parser];
            if( _error ) {
                return nil;
            }
            if( argExpression == nil) {
                _error = [[TCError alloc]initWithCode:TCERROR_EXP_ARGUMENT withArgument:nil];
                return nil;
            }
            if(!atom.subNodes) {
                atom.subNodes = [NSMutableArray array];
            }
            [atom.subNodes addObject:argExpression];
            requireComma = YES;
        }
        
        return atom;
    }
    
    // No special cases hit, just return the identifier node.
    
    return atom;
}

/**
 Parse an expression atom, which is typically a unary operation, a symbol,
 a constant, or a (subexpression).
 @param parser the active parsing structure used to lex tokens.
 @return a node (or tree) representing the atom or subexpression.
 */

-(TCSyntaxNode*) parseAtom:(TCParser*) parser
{
    if([parser isNextToken:TOKEN_ADD]) {
        ; // No action, we skip a spurioius "+"
    }
    
    // Look for leading negation or boolean not which implies monadic operator
    if([parser isNextToken:TOKEN_SUBTRACT] ||
       [parser isNextToken:TOKEN_NOT]) {
        TCSyntaxNode *atom = [[TCSyntaxNode alloc]init];
        atom.nodeType = LANGUAGE_MONADIC;
        atom.action = [parser lastTokenType];
        atom.spelling = [parser lastSpelling];
        
        TCSyntaxNode *target = [self parseAtom:parser];
        if( target != nil ) {
            atom.subNodes = [NSMutableArray arrayWithArray:@[target]];
            return atom;
        }
        [parser error:TCERROR_OPERANDNF];
        return nil;
    }
    
    // See if it is an identifier.  This requires extra processing.
    if([parser isNextToken:TOKEN_IDENTIFIER]) {
        return [self parseIdentifier:parser];
    }
    
    //  Is this a (subexpression)?  If so, parse the parenthesis and
    //  start expression processing again from the top of the order
    //  hierarchy. Requires a closing parenthesis after the expression.
    
    if([parser isNextToken:TOKEN_PAREN_LEFT]) {
        TCSyntaxNode * subExpression = [self parseBoolean:parser];
        if(![parser isNextToken:TOKEN_PAREN_RIGHT]) {
            [parser error:TCERROR_PARENMISMATCH];
            return nil;
        }
        return subExpression;
    }
    
    //  Is this a constant value?  If so, create a node for each possible
    //  constant type.
    
    if([parser isNextToken:TOKEN_INTEGER]) {
        TCSyntaxNode * atom = [[TCSyntaxNode alloc]init];
        atom.nodeType = LANGUAGE_SCALAR;
        atom.action = TOKEN_INTEGER;
        atom.spelling = [parser lastSpelling];
        return atom;
        
        if([parser isNextToken:TOKEN_DOUBLE]) {
            TCSyntaxNode *atom = [[TCSyntaxNode alloc]init];
            atom.nodeType = LANGUAGE_SCALAR;
            atom.action = TOKEN_DOUBLE;
            atom.spelling = [parser lastSpelling];
            return atom;
        }
    }
    
    //  An unrecognized expression atom, so we are probably at the end of
    //  the expression (or hit a syntax error).  Indicate there are no
    //  more tokens here.
    
    return nil;
}

/**
 Parse diadic multiply or divide operations.
 
 Parses an atom (which can be an entire subexpression) and if this is
 followed by a "*" or "/" operator then create a node for a DIADIC
 operator and use the token as the action code.  Requires a valid
 right and left side or we just return the first side found.
 
 @param parser the active lexical parser
 @returns a tree node with a left and right side for each side of
 the diadic operator, or a node representing the subordinate expression
 component.
 */
-(TCSyntaxNode*) parseMultiplyDivide:(TCParser*) parser
{
    
    
    TCSyntaxNode * atom = [self parseAtom:parser];
    if( !atom )
        return nil;
    
    while( [parser isNextToken:TOKEN_MULTIPLY] ||
       [parser isNextToken:TOKEN_DIVIDE]) {
        TokenType whichOperation = [parser lastTokenType];
        NSString * spelling = [parser lastSpelling];
        
        TCSyntaxNode * rightSide = [self parseAtom:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [[TCSyntaxNode alloc]init];
            thisRelation.nodeType = LANGUAGE_DIADIC;
            thisRelation.action = whichOperation;
            thisRelation.spelling = spelling;
            [thisRelation addNode:atom];
            [thisRelation addNode:rightSide];
            atom = thisRelation;
        }
    }
    return atom;
}


/**
 Parse diadic add or subtract operations.
 
 Parses an atom (which can be an entire subexpression) and if this is
 followed by a "+" or "-" operator then create a node for a DIADIC
 operator and use the token as the action code.  Requires a valid
 right and left side or we just return the first side found.
 
 @param parser the active lexical parser
 @returns a tree node with a left and right side for each side of
 the diadic operator, or a node representing the subordinate expression
 component.
 */

-(TCSyntaxNode*) parseAddSubtract:(TCParser*) parser
{
    TCSyntaxNode * atom = [self parseMultiplyDivide:parser];
    if( !atom )
        return nil;
    
    while( [parser isNextToken:TOKEN_ADD] ||
       [parser isNextToken:TOKEN_SUBTRACT]) {
        TokenType whichOperation = [parser lastTokenType];
        NSString * spelling = [parser lastSpelling];
        
        TCSyntaxNode * rightSide = [self parseMultiplyDivide:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [[TCSyntaxNode alloc]init];
            thisRelation.nodeType = LANGUAGE_DIADIC;
            thisRelation.action = whichOperation;
            thisRelation.spelling = spelling;
            [thisRelation addNode:atom];
            [thisRelation addNode:rightSide];
            atom = thisRelation;
        }
    }
    return atom;
}


/**
 Parse diadic boolean AND and OR operations.
 
 Parses an atom (which can be an entire subexpression) and if this is
 followed by a "&&" or "||" operator then create a node for a DIADIC
 operator and use the token as the action code.  Requires a valid
 right and left side or we just return the first side found.
 
 @param parser the active lexical parser
 @returns a tree node with a left and right side for each side of
 the diadic operator, or a node representing the subordinate expression
 component.
 */

-(TCSyntaxNode*) parseBoolean:(TCParser* ) parser
{
    TCSyntaxNode * atom = [self parseRelations:parser];
    if( !atom )
        return nil;
    
    if([parser isNextToken:TOKEN_BOOLEAN_AND] ||
       [parser isNextToken:TOKEN_BOOLEAN_OR]) {
        TokenType whichRelation = [parser lastTokenType];
        NSString * spelling = [parser lastSpelling];
        
        TCSyntaxNode * rightSide = [self parseRelations:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [[TCSyntaxNode alloc]init];
            thisRelation.nodeType = LANGUAGE_DIADIC;
            thisRelation.action = whichRelation;
            thisRelation.spelling = spelling;
            [thisRelation addNode:atom];
            [thisRelation addNode:rightSide];
            return thisRelation;
        }
    }
    return atom;
}


/**
 Parse diadic relational comparison operations.
 
 Parses an atom (which can be an entire subexpression) and if this is
 followed by a relational operator such as "<" or ">=" then create a 
 node for a RELATION operator and use the token as the action code.  
 Requires a valid right and left side or we just return the first 
 side found.
 
 Note that this could be implemented as a DIADIC operator with the
 action representing the specific form of relationship comparison.
 
 @param parser the active lexical parser
 @returns a tree node with a left and right side for each side of
 the diadic operator, or a node representing the subordinate expression
 component.
 */


-(TCSyntaxNode*) parseRelations:(TCParser *) parser
{
    TCSyntaxNode * atom = [self parseAddSubtract:parser];
    if( !atom )
        return nil;
    
    if([parser isNextToken:TOKEN_GREATER_OR_EQUAL] ||
       [parser isNextToken:TOKEN_GREATER] ||
       [parser isNextToken:TOKEN_LESS] ||
       [parser isNextToken:TOKEN_LESS_OR_EQUAL] ||
       [parser isNextToken:TOKEN_EQUAL] ||
       [parser isNextToken:TOKEN_NOT_EQUAL]) {
        TokenType whichRelation = [parser lastTokenType];
        NSString * spelling = [parser lastSpelling];
        
        TCSyntaxNode * rightSide = [self parseAddSubtract:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [[TCSyntaxNode alloc]init];
            thisRelation.nodeType = LANGUAGE_RELATION;
            thisRelation.action = whichRelation;
            thisRelation.spelling = spelling;
            [thisRelation addNode:atom];
            [thisRelation addNode:rightSide];
            return thisRelation;
        }
    }
    return atom;
}

/**
 Given a parser, create a parse tree for a standard expression and return it
 as the method result.  Returns nil if no expression was found.
 */

-(TCSyntaxNode*) parse:(TCParser *)parser
{
    
    long startingLocation = [parser position];
    TCSyntaxNode * tree = [self parseBoolean:parser];
    if (!tree) {
        [parser setPosition:startingLocation];
        _error = [parser error];
        return nil;
    }
    
    TCSyntaxNode * root = [[TCSyntaxNode alloc]init];
    root.nodeType = LANGUAGE_EXPRESSION;
    root.subNodes = [NSMutableArray arrayWithArray:@[tree]];
    _error = parser.error;
    
    return root;
}

@end
