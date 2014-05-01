//
//  ExpressionParser.m
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import "TCExpressionParser.h"
#import "TCAssignmentParser.h"
#import "TCError.h"
#import "TCTypeParser.h"



@implementation TCExpressionParser

- (TCSyntaxNode*)parseIncrement:(TCSymtanticParser*) parser forIdentifier:(NSString*) name
{
    TCSyntaxNode *atom = [TCSyntaxNode node:LANGUAGE_REFERENCE];
    
    // Create a new expression tree with one branch
    // that describes the increment or decrement, and
    // a second that gets the reference value.
    
    BOOL increment = (parser.lastTokenType == TOKEN_INCREMENT);
    
    // This must be followed by an identifier if we do not already have
    // such an identifier name in hand.  This means this was a prefix
    // operation and the name must follow it.
    
    BOOL isPre = NO;
    if( !name ) {
        if(![parser isNextToken:TOKEN_IDENTIFIER]) {
            parser.error = [[TCError alloc]initWithCode:TCERROR_IDENTIFIERNF withArgument:nil];
            return nil;
        }
        name = parser.lastSpelling;
        atom.position = parser.tokenPosition;
        isPre = YES;
    }
    
    // Create the increment operation
    
    TCSyntaxNode * aStmt = [TCSyntaxNode node:LANGUAGE_ASSIGNMENT];
    aStmt.position = parser.tokenPosition;
    
    TCSyntaxNode * lvalue = [TCSyntaxNode node:LANGUAGE_ADDRESS];
    lvalue.position = parser.tokenPosition;
    lvalue.spelling = name;
    
    TCSyntaxNode * rvalue = [TCSyntaxNode node:LANGUAGE_DIADIC];
    rvalue.action = TOKEN_ADD;
    rvalue.position = parser.tokenPosition;
    
    TCSyntaxNode * rvalueName = [TCSyntaxNode node:LANGUAGE_REFERENCE];
    rvalueName.position = parser.tokenPosition;
    rvalueName.spelling = name;
    
    TCSyntaxNode * rvalueInc = [TCSyntaxNode node:LANGUAGE_SCALAR];
    rvalueInc.action = TOKEN_INTEGER;
    rvalueInc.spelling = @"1";
    
    if( increment) {
        rvalue.subNodes = [NSMutableArray arrayWithArray:@[rvalueName, rvalueInc]];
    } else {
        TCSyntaxNode * neg = [TCSyntaxNode node:LANGUAGE_MONADIC];
        neg.action = TOKEN_MINUS;
        neg.subNodes = [NSMutableArray arrayWithArray:@[rvalueInc]];
        rvalue.subNodes = [NSMutableArray arrayWithArray:@[rvalueName, neg]];
    }
    
    aStmt.subNodes = [NSMutableArray arrayWithArray:@[lvalue, rvalue]];
    atom.nodeType = LANGUAGE_EXPRESSION;
    
    // The order of the subnodes depends on whether this is a post- or
    // pre-increment operation. The EXPRESSION interpreter always uses
    // the first subexpression but executes them all.  So we either use
    // the result of the increment (pre-op) or the value before the
    // increment (post-op)
    
    if( isPre)
        atom.subNodes = [NSMutableArray arrayWithArray:@[aStmt]];
    else
        atom.subNodes = [NSMutableArray arrayWithArray:@[rvalueName, aStmt]];
    
    return atom;
}


- (TCSyntaxNode*)parseIdentifier:(TCSymtanticParser *)parser
{
    TCSyntaxNode *atom = [TCSyntaxNode node:LANGUAGE_REFERENCE];
    atom.spelling = [parser lastSpelling];
    atom.position = parser.tokenPosition;
    
    
    // Let's check for cases other than the simplest reference
    // to a variable.
    
    // @NOTE I think we have a problem here in that we do not
    // handle post operations correctly -- they would be the
    // same as pre-operations.  Need to know when that is the
    // case, and order the expression nodes backwards.  Also,
    // need to be able to get reference to item and resolve it
    // before allowing post-op to occur on target value.  I.e.
    // get value of before calculating new value.
    
    
    // Is it a pre- increment or decrement operation?
    
    if([parser isNextToken:TOKEN_INCREMENT] ||
       [parser isNextToken:TOKEN_DECREMENT]) {
        
        return [self parseIncrement:parser forIdentifier:atom.spelling];
        
    }
    
    
    // Is it an array reference?
    
    if([parser isNextToken:TOKEN_BRACKET_LEFT]) {
        TCSyntaxNode * arrayExpression = [self parseRelations:parser];
        if( arrayExpression == nil)
            return nil;
        if(![parser isNextToken:TOKEN_BRACKET_RIGHT]) {
            parser.error = [[TCError alloc]initWithCode:TCERROR_BRACEMISMATCH withArgument:nil];
            return nil;
        }
        TCSyntaxNode * deref = [TCSyntaxNode node:LANGUAGE_DEREFERENCE];
        deref.position = parser.tokenPosition;
        deref.spelling = atom.spelling;
        deref.subNodes = [NSMutableArray arrayWithArray:@[atom]];
        atom.nodeType = LANGUAGE_ARRAY;
        atom.subNodes = [NSMutableArray arrayWithArray:@[arrayExpression]];
        
        return deref;
    }
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

-(TCSyntaxNode*) parseAtom:(TCSymtanticParser*) parser
{
    if([parser isNextToken:TOKEN_ADD]) {
        ; // No action, we skip a spurioius "+"
    }
    
    // Look for 'char' datum
    if([parser isNextToken:TOKEN_CHAR]) {
        TCSyntaxNode * c = [TCSyntaxNode node:LANGUAGE_SCALAR];
        c.action = TOKEN_INTEGER;
        
        if(parser.lastSpelling.length == 1) {
            int ch = [parser.lastSpelling characterAtIndex:0];
            c.spelling = [NSString stringWithFormat:@"%d",ch ];
        }
        else
            if([parser.lastSpelling isEqualToString:@"\\n"])
                c.spelling = [NSString stringWithFormat:@"%d",'\n'];
            else if([parser.lastSpelling isEqualToString:@"\\t"])
                c.spelling = [NSString stringWithFormat:@"%d",'\t'];
            else if([parser.lastSpelling isEqualToString:@"\\'"])
                c.spelling = [NSString stringWithFormat:@"%d",'\''];
            else if([parser.lastSpelling isEqualToString:@"\\\""])
                c.spelling = [NSString stringWithFormat:@"%d",'\"'];
            else if([parser.lastSpelling isEqualToString:@"\\r"])
                c.spelling = [NSString stringWithFormat:@"%d",'\r'];
            else if([parser.lastSpelling isEqualToString:@"\\0"])
                c.spelling = [NSString stringWithFormat:@"%d",'\0'];
            else c.spelling = @"<invalid character constant>";
        return c;
        
    }
    
    // Look for leading pre-increment or -decrement, which takes us into the
    // identifier parser.
    
    if([parser isNextToken:TOKEN_INCREMENT] ||
       [parser isNextToken:TOKEN_DECREMENT]) {
        return [self parseIncrement:parser forIdentifier:nil];
    }
    
    
    // Look for leading negation or boolean not which implies monadic operator
    if([parser isNextToken:TOKEN_SUBTRACT] ||
       [parser isNextToken:TOKEN_NOT]) {
        TCSyntaxNode *atom = [TCSyntaxNode node:LANGUAGE_MONADIC];
        atom.position = parser.tokenPosition;
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
        TCSyntaxNode * deref = [TCSyntaxNode node:LANGUAGE_ADDRESS];
        deref.argument = nil;
        deref.action = 0;
        deref.position = parser.tokenPosition;
        deref.subNodes = [NSMutableArray arrayWithArray:@[source]];
        return deref;
        
    }
    // See if this is an address-of operator
    
    if([parser isNextToken:TOKEN_AMPER]) {
        
        TCSyntaxNode * target = [TCSyntaxNode node:LANGUAGE_ADDRESS];
        target.position = parser.tokenPosition;
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
    // See if it is an identifier.  This requires extra processing, such as
    // checking function or array references
    
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
            
            subExpression = [TCSyntaxNode node:LANGUAGE_CAST];
            subExpression.position = parser.tokenPosition;
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
            TCSyntaxNode * sourceExpression = nil;
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
        TCSyntaxNode * atom = [TCSyntaxNode node:LANGUAGE_SCALAR];
        atom.position = parser.tokenPosition;
        atom.action = TOKEN_INTEGER;
        atom.spelling = [parser lastSpelling];
        return atom;
    }
    else if([parser isNextToken:TOKEN_DOUBLE]) {
        TCSyntaxNode *atom = [TCSyntaxNode node:LANGUAGE_SCALAR];
        atom.position = parser.tokenPosition;
        atom.action = TOKEN_DOUBLE;
        atom.spelling = [parser lastSpelling];
        return atom;
    }
    else if([parser isNextToken:TOKEN_STRING]) {
        TCSyntaxNode * atom = [TCSyntaxNode node:LANGUAGE_SCALAR];
        atom.position = parser.tokenPosition;
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
-(TCSyntaxNode*) parseMultiplyDivide:(TCSymtanticParser*) parser
{
    
    
    TCSyntaxNode * atom = [self parseAtom:parser];
    if( !atom )
        return nil;
    
    while([parser isNextToken:TOKEN_ASTERISK] ||
          [parser isNextToken:TOKEN_PERCENT] ||
          [parser isNextToken:TOKEN_DIVIDE]) {
        long position = parser.tokenPosition;
        
        TokenType whichOperation = [parser lastTokenType];
        NSString * spelling = [parser lastSpelling];
        
        TCSyntaxNode * rightSide = [self parseAtom:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [TCSyntaxNode node:LANGUAGE_DIADIC];
            thisRelation.position = position;
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

-(TCSyntaxNode*) parseAddSubtract:(TCSymtanticParser*) parser
{
    TCSyntaxNode * atom = [self parseMultiplyDivide:parser];
    if( !atom )
        return nil;
    
    while( [parser isNextToken:TOKEN_ADD] ||
          [parser isNextToken:TOKEN_SUBTRACT]) {
        TokenType whichOperation = [parser lastTokenType];
        long position = parser.tokenPosition;
        NSString * spelling = [parser lastSpelling];
        
        TCSyntaxNode * rightSide = [self parseMultiplyDivide:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [TCSyntaxNode node:LANGUAGE_DIADIC];
            thisRelation.action = whichOperation;
            thisRelation.spelling = spelling;
            thisRelation.position = position;
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

-(TCSyntaxNode*) parseBoolean:(TCSymtanticParser* ) parser
{
    TCSyntaxNode * atom = [self parseRelations:parser];
    if( !atom )
        return nil;
    
    if([parser isNextToken:TOKEN_BOOLEAN_AND] ||
       [parser isNextToken:TOKEN_BOOLEAN_OR]) {
        TokenType whichRelation = [parser lastTokenType];
        NSString * spelling = [parser lastSpelling];
        long position = parser.tokenPosition;
        
        TCSyntaxNode * rightSide = [self parseRelations:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [TCSyntaxNode node:LANGUAGE_DIADIC];
            thisRelation.action = whichRelation;
            thisRelation.spelling = spelling;
            thisRelation.position = position;
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


-(TCSyntaxNode*) parseRelations:(TCSymtanticParser *) parser
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
        long position = parser.tokenPosition;
        
        TCSyntaxNode * rightSide = [self parseAddSubtract:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [TCSyntaxNode node:LANGUAGE_RELATION];
            thisRelation.action = whichRelation;
            thisRelation.spelling = spelling;
            thisRelation.position = position;
            [thisRelation addNode:atom];
            [thisRelation addNode:rightSide];
            return thisRelation;
        }
    }
    return atom;
}



-(TCSyntaxNode*) parseAssignment:(TCSymtanticParser *) parser
{
    long savedPosition = parser.position;
    
    TCSyntaxNode * atom = [self parseBoolean:parser];
    if( !atom )
        return nil;
    
    if([parser isNextToken:TOKEN_ASSIGNMENT]) {
        
        // If it was an assignment then we have to back up and fix the parsing
        // of the LVALUE side.
        parser.position = savedPosition;
        TCAssignmentParser * p = [[TCAssignmentParser alloc]init];
        atom = [p parse:parser];
        if( !atom || parser.error) {
            parser.position = savedPosition;
            return nil;
        }
        
        // Now record the location of the assignment RVALUE and parse that.
        
        long tokenPosition = parser.tokenPosition;
        
        TCSyntaxNode * rightSide = [self parseBoolean:parser];
        if( rightSide) {
            TCSyntaxNode *thisRelation = [TCSyntaxNode node:LANGUAGE_ASSIGNMENT];
            thisRelation.position = tokenPosition;
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

-(TCSyntaxNode*) parse:(TCSymtanticParser *)parser
{
    
    long startingLocation = [parser position];
    long sourcelocation = parser.tokenPosition;
    
    TCSyntaxNode * tree = [self parseAssignment:parser];
    if (!tree) {
        [parser setPosition:startingLocation];
        _error = [parser error];
        return nil;
    }
    
    TCSyntaxNode * root = [TCSyntaxNode node:LANGUAGE_EXPRESSION];
    root.position = sourcelocation;
    root.subNodes = [NSMutableArray arrayWithArray:@[tree]];
    _error = parser.error;
    
    return root;
}

@end
