//
//  TCIfParser.m
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//  Process a C IF statement.  This has a condition clause, a true-branch
//  and an optional false-branch each of which could be a statement.  This
//  results in a parse tree like this:
//
//                          LANGUAGE_IF
//                               |
//            +------------------+--------------------+
//            |                  |                    |
//    LANGUAGE_EXPRESSION   <true-branch>      <false-branch>
//      <condition>                              (optional)
//
//  The branch subnodes may be statements or blocks.  If the false
//  branch ("else" clause) is not present then there are only two
//  subnodes.


#import "TCIfParser.h"
#import "TCExpressionParser.h"
#import "TCStatementParser.h"

@implementation TCIfParser



-(TCSyntaxNode*) parse:(TCLexicalScanner *)scanner
{
    
    // Is this an IF statement?
    
    long savedPosition = scanner.position;
    if([scanner isNextToken:TOKEN_IF]) {
        
        // A valid IF statement must be followed by the condition in
        // parenthesis.
        
        if([scanner isNextToken:TOKEN_PAREN_LEFT]) {

            // Create the initial tree and save it's source position
            TCSyntaxNode * tree = [TCSyntaxNode node:LANGUAGE_IF usingScanner:scanner];
            tree.position = scanner.tokenPosition;
            
            // Parse the conditional expression.
            TCExpressionParser *exp = [[TCExpressionParser alloc]init];
            TCSyntaxNode * expTree = [exp parse:scanner];
            if(expTree == nil || exp.error != nil )
                return nil;
            
            // Create the subnodes for the LANGUAGE_IF statement, and store
            // the condition as the first element.
            tree.subNodes = [[NSMutableArray alloc]init];
            [tree.subNodes addObject:expTree];
            
            // If no closing parenthesis then error
            if(![scanner isNextToken:TOKEN_PAREN_RIGHT]) {
                scanner.error = [[TCError alloc]initWithCode:TCERROR_PARENMISMATCH usingScanner:scanner];
                return nil;
            }
            
            
            // Parse the conditional statement (the "true branch").  This can be
            // any statement or block.  We use the TCSTATEMENT_SUBSTATEMENT flag
            // to indicate that this statement is not a standalone statement but
            // is part of a larger statement; this helps manage the trailing ";"
            // character properly.
            //
            // If there is an error while parsing, bail out.
            
            TCStatementParser * stmt = [[TCStatementParser alloc] init];
            TCSyntaxNode * condStatement = [stmt parse:scanner options:TCSTATEMENT_SUBSTATEMENT];
            if(condStatement == nil) {
                scanner.error = [[TCError alloc]initWithCode:TCERROR_EXP_EXPRESSION usingScanner:scanner];
            }
            if(scanner.error != nil) {
                return nil;
            }
            
            // Add the statement as the second subnode
            [tree.subNodes addObject:condStatement];
            
            // Three might be an optional ELSE clause.  If so, then parse that as
            // well. If there is an error, bail out.  Otherwise add it as the
            // third node in the subtree.
            if( [scanner isNextToken:TOKEN_ELSE]) {

                condStatement = [stmt parse:scanner options:TCSTATEMENT_SUBSTATEMENT];
                if(condStatement == nil || scanner.error != nil ) {
                    return nil;
                }
                [tree.subNodes addObject:condStatement];
            }
            
            // All done, we have three subnodes to LANGUAGE_IF.  Return the tree.
            return tree;

        }
    }
    
    // We did not find an "if" keyword followed by "(" to signify the start of
    // a valid IF statement.  Reset the pointer and bail out, so the caller can
    // try something else.
    [scanner setPosition:savedPosition];
    return nil;
    }

@end
