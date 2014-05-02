//
//  TCStatement.m
//  Language
//
//  Created by Tom Cole on 4/7/14.
//
//

#import "TCStatementParser.h"
#import "TCDeclarationParser.h"
#import "TCAssignmentParser.h"
#import "TCExpressionParser.h"
#import "TCIfParser.h"

@implementation TCStatementParser

/**
 Helper function that doesn't require options - assumes none are given
 */
-(TCSyntaxNode*) parse:(TCSymtanticParser*)parser;
{
    return [self parse:parser options:TCSTATEMENT_NONE];
}


-(TCSyntaxNode*) parse:(TCSymtanticParser*)parser options:(TCStatementOptions) options
{
    TCSyntaxNode * tree = nil;
    
    // See if this is an empty statement
    
    if([parser isNextToken:TOKEN_SEMICOLON])
        return nil;
    
    // See if this is a basic block
    
    if( [parser isNextToken:TOKEN_BRACE_LEFT]) {
        //NSLog(@"PARSE Basic block");
        
        tree = [TCSyntaxNode node:LANGUAGE_BLOCK];
        tree.position = parser.tokenPosition;
        
        while(1) {
            if([parser isNextToken:TOKEN_BRACE_RIGHT])
                break;
            
            TCSyntaxNode * stmt = [self parse:parser];
            if( parser.error != nil)
                return nil;
            if( tree.subNodes == nil) {
                tree.subNodes = [[NSMutableArray alloc]init];
            }
            if( stmt != nil)
                [tree.subNodes addObject:stmt];
        }
        // Basic block never expects/uses trailing semicolon, so we are done here.
        return tree;
    }
    
    // Try each kind of statement in turn.
    
    // CONTINUE
    if( tree == nil ) {
        if([parser isNextToken:TOKEN_CONTINUE]) {
            TCSyntaxNode * stmt = [TCSyntaxNode node:LANGUAGE_CONTINUE];
            stmt.position = parser.tokenPosition;
            return stmt;
        }
    }
    
    // BREAK
    if( tree == nil ) {
        if([parser isNextToken:TOKEN_BREAK]) {
            TCSyntaxNode * stmt = [TCSyntaxNode node:LANGUAGE_BREAK];
            stmt.position = parser.tokenPosition;
            return stmt;
        }
    }
    // RETURN
    if( tree == nil ) {
        if( [parser isNextToken:TOKEN_RETURN]) {
            TCExpressionParser * expr = [[TCExpressionParser alloc]init];

            TCSyntaxNode * ret = [TCSyntaxNode node:LANGUAGE_RETURN];
            ret.position = parser.tokenPosition;
            ret.subNodes = [NSMutableArray arrayWithArray:@[[expr parse:parser]]];
            if(parser.error)
                return nil;
            return ret;
        }
    }
    
    // DECLARATION
    
    if( tree == nil ) {
        TCDeclarationParser * declaration = [[TCDeclarationParser alloc] init];
        tree = [declaration parse:parser];
        if( parser.error != nil) {
            return nil;
        }
    }
    
    // ASSIGNMENT
    if( tree == nil ) {
        
        TCAssignmentParser * assignment = [[TCAssignmentParser alloc] init];
        tree = [assignment parse:parser];
        if( parser.error != nil ) {
            return nil;
        }
    }
    
    // FOR
    if( tree == nil ) {
        
        long savedPosition = parser.position;
        if([parser isNextToken:TOKEN_FOR]) {
            long tokenPosition = parser.tokenPosition;
            
            if([parser isNextToken:TOKEN_PAREN_LEFT]) {
                
                // There are three statement groups separated by ";" characters
                parser.error = nil;
                TCStatementParser * clause = [[TCStatementParser alloc]init];
                TCSyntaxNode * initClause = nil;
                TCSyntaxNode * termClause = nil;
                TCSyntaxNode * incrementClause = nil;
                TCSyntaxNode * block = nil;
                
                // Initialization
                initClause = [clause parse:parser options:TCSTATEMENT_NONE];
                if( initClause == nil || parser.error) {
                    tree = nil;
                }
                else {
                    termClause = [clause parse:parser options:TCSTATEMENT_NONE];
                    if( termClause == nil || parser.error) {
                        tree = nil;
                    }
                    else {
                        incrementClause = [clause parse:parser options:TCSTATEMENT_SUBSTATEMENT];
                        if( incrementClause == nil || parser.error) {
                            tree = nil;
                        }
                        else {
                            if( ![parser isNextToken:TOKEN_PAREN_RIGHT]) {
                                parser.error = [[TCError alloc]initWithCode:TCERROR_PARENMISMATCH withArgument:nil];
                            } else {
                                block = [clause parse:parser options:TCSTATEMENT_NONE];
                                if( block == nil || parser.error) {
                                    tree = nil;
                                } else {
                                    tree = [TCSyntaxNode node:LANGUAGE_FOR];
                                    tree.position = tokenPosition;
                                    tree.subNodes = [NSMutableArray arrayWithArray:@[initClause, termClause, incrementClause, block]];
                                    return tree;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // If after all that, if we failed to parse the three clauses then we are not an IF statement.
        
        if( !tree) {
            parser.position = savedPosition;
        }
    }
    
    // WHILE
    // Note that this is really the same a FOR but without an initializer or increment clause.
    if( tree == nil ) {
        
        long savedPosition = parser.position;
        if([parser isNextToken:TOKEN_WHILE]) {
            long tokenPosition = parser.tokenPosition;
            
            if([parser isNextToken:TOKEN_PAREN_LEFT]) {
                
                // There is a single term clause and a body to process
                parser.error = nil;
                TCStatementParser * clause = [[TCStatementParser alloc]init];
                TCSyntaxNode * termClause = nil;
                TCSyntaxNode * block = nil;
                
                termClause = [clause parse:parser options:TCSTATEMENT_SUBSTATEMENT];
                if( termClause == nil || parser.error) {
                    tree = nil;
                }
                else {
                    if( ![parser isNextToken:TOKEN_PAREN_RIGHT]) {
                        parser.error = [[TCError alloc]initWithCode:TCERROR_PARENMISMATCH withArgument:nil];
                    } else {
                        block = [clause parse:parser options:TCSTATEMENT_NONE];
                        if( block == nil || parser.error) {
                            tree = nil;
                        } else {
                            tree = [TCSyntaxNode node:LANGUAGE_WHILE];
                            tree.position = tokenPosition;
                            tree.subNodes = [NSMutableArray arrayWithArray:@[termClause, block]];
                            return tree;
                        }
                    }
                }
            }
        }
        
        
        // If after all that, if we failed to parse the three clauses then we are not an IF statement.
        
        if( !tree) {
            parser.position = savedPosition;
        }
    }
    
    // IF [ELSE]
    if( tree == nil ) {
        TCIfParser * ifStatement = [[TCIfParser alloc] init];
        tree = [ifStatement parse:parser];
        if( parser.error != nil) {
            return nil;
        }
        
        // If the last subnode in the IF statement is a block,
        // then we do not expect to have a trailing ";" for
        // this statement.
        
        int subNodeCount = (int)[tree.subNodes count];
        if( subNodeCount > 0 ) {
            TCSyntaxNode * lastNode = tree.subNodes[subNodeCount-1];
            if( lastNode.nodeType == LANGUAGE_BLOCK) {
                // NSLog(@"if-statement ends in block; no ';' required");
                return tree;
            }
        }
    }
    
    // How about a simple expression? Which can include function calls with discarded result values
    if( tree == nil ) {
        
        TCExpressionParser * exp = [[TCExpressionParser alloc]init];
        tree = [exp parse:parser];
        if( parser.error != nil) {
            return nil;
        }
    }
    
    if(tree != nil) {
        if(!(options & TCSTATEMENT_SUBSTATEMENT)) {
            // NSLog(@"PARSE require ';'");
            
            if(![parser isNextToken:TOKEN_SEMICOLON]) {
                
                [parser error:TCERROR_SEMICOLON];
                return nil;
                
            }
        }
        
        return tree;
    }
    
    parser.error = [[TCError alloc]initWithCode:TCERROR_UNK_STATEMENT withArgument:[parser lastSpelling]];
    return nil;
}

@end