//
//  ExpressionParser.m
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import "TCExpressionParser.h"
#import "TCError.h"
#import "TCTypeParser.h"



@implementation TCExpressionParser

- (TCSyntaxNode*)parseIdentifier:(TCParser *)parser
{
    TCSyntaxNode *atom = [TCSyntaxNode node];
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
        TCSyntaxNode *atom = [TCSyntaxNode node];
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
    
    // See if this is a pointer-dereference operator
    
    if([parser isNextToken:TOKEN_ASTERISK]) {
        TCSyntaxNode * source = [self parseAtom:parser];
        if( source == nil)
            return nil;
        TCSyntaxNode * deref = [TCSyntaxNode node];
        deref.nodeType = LANGUAGE_ADDRESS;
        deref.argument = nil;
        deref.action = 0;
        deref.subNodes = [NSMutableArray arrayWithArray:@[source]];
        return deref;
        
    }
    // See if this is an address-of operator
    
    if([parser isNextToken:TOKEN_AMPER]) {
        
        TCSyntaxNode * target = [TCSyntaxNode node];
        target.nodeType = LANGUAGE_ADDRESS;

        /**
         @NOTE need to handle complex & values instead of just
         simple scalar ones.
         */
        if( ![parser isNextToken:TOKEN_IDENTIFIER]) {
            _error = [[TCError alloc]initWithCode:TCERROR_IDENTIFIERNF withArgument:nil];
            return nil;
        }
        target.spelling = [parser lastSpelling];
        
        return target;
        
    }
    // See if it is an identifier.  This requires extra processing.
    if([parser isNextToken:TOKEN_IDENTIFIER]) {
        return [self parseIdentifier:parser];
    }
    
    //  Is this a (subexpression) or a (cast)?  If so, parse the parenthesis
    //  and see what follows.  First, try parsing a type definition, and if
    //  that doesnt' work then start expression processing again from the
    //  top of the precidence hierarchy. Either case requires a closing
    //  parenthesis after the expression.
    
    if([parser isNextToken:TOKEN_PAREN_LEFT]) {
        
        TCSyntaxNode * subExpression = nil;
        
        subExpression = [[[TCTypeParser alloc]init] parse:parser];
        
        // If it is a TYPE then this is a cast.  Create a CAST node
        // with the subnode being the type data.
        
        if( subExpression != nil ) {
            TCSyntaxNode * cast = subExpression;
            
            subExpression = [TCSyntaxNode node];
    
            subExpression.nodeType = LANGUAGE_CAST;
            subExpression.subNodes = [NSMutableArray arrayWithArray:@[cast]];
        }
        
        // It wasn't a cast, see if it is a top-level expression which starts
        // at the assignment parse.
        
        if( subExpression == nil ) {
            subExpression = [self parseAssignment:parser];
        }
        
        // If we have something (either a cast or an expression) then we
        // must find a closing parenthesis
        
        if( subExpression != nil ) {
            if(![parser isNextToken:TOKEN_PAREN_RIGHT]) {
                [parser error:TCERROR_PARENMISMATCH];
                return nil;
            }
        }
        
        // If it was a cast, then it is followed by another expression which is
        // made the other subnode of the CAST operation
        
        if( subExpression.nodeType == LANGUAGE_CAST) {
            TCSyntaxNode * sourceExpression = [TCSyntaxNode node];
            sourceExpression = [self parseAssignment:parser];
            if( sourceExpression == nil) {
                parser.error = [[TCError alloc]initWithCode:TCERROR_EXP_EXPRESSION withArgument:nil];
                return nil;
            }
            [subExpression.subNodes addObject:sourceExpression];
        }
        return subExpression;
    }
    
    //  Is this a constant value?  If so, create a node for each possible
    //  constant type.
    
    if([parser isNextToken:TOKEN_INTEGER]) {
        TCSyntaxNode * atom = [TCSyntaxNode node];
        atom.nodeType = LANGUAGE_SCALAR;
        atom.action = TOKEN_INTEGER;
        atom.spelling = [parser lastSpelling];
        return atom;
    }
    else if([parser isNextToken:TOKEN_DOUBLE]) {
        TCSyntaxNode *atom = [TCSyntaxNode node];
        atom.nodeType = LANGUAGE_SCALAR;
        atom.action = TOKEN_DOUBLE;
        atom.spelling = [parser lastSpelling];
        return atom;
    }
    else if([parser isNextToken:TOKEN_STRING]) {
        TCSyntaxNode * atom = [TCSyntaxNode node];
        atom.nodeType = LANGUAGE_SCALAR;
        atom.action = TOKEN_STRING;
        atom.spelling = [parser lastSpelling];
        return atom;
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
    
    while( [parser isNextToken:TOKEN_ASTERISK] ||
          [parser isNextToken:TOKEN_DIVIDE]) {
        TokenType whichOperation = [parser lastTokenType];
        NSString * spelling = [parser lastSpelling];
        
        TCSyntaxNode * rightSide = [self parseAtom:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [TCSyntaxNode node];
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
            TCSyntaxNode *thisRelation = [TCSyntaxNode node];
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
            TCSyntaxNode *thisRelation = [TCSyntaxNode node];
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
            TCSyntaxNode *thisRelation = [TCSyntaxNode node];
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



-(TCSyntaxNode*) parseAssignment:(TCParser *) parser
{
    TCSyntaxNode * atom = [self parseBoolean:parser];
    if( !atom )
        return nil;
    
    if([parser isNextToken:TOKEN_ASSIGNMENT]) {
        
        TCSyntaxNode * rightSide = [self parseBoolean:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [TCSyntaxNode node];
            thisRelation.nodeType = LANGUAGE_ASSIGNMENT;
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
    TCSyntaxNode * tree = [self parseAssignment:parser];
    if (!tree) {
        [parser setPosition:startingLocation];
        _error = [parser error];
        return nil;
    }
    
    TCSyntaxNode * root = [TCSyntaxNode node];
    root.nodeType = LANGUAGE_EXPRESSION;
    root.subNodes = [NSMutableArray arrayWithArray:@[tree]];
    _error = parser.error;
    
    return root;
}

@end
