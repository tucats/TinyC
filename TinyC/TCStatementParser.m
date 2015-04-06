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
-(TCSyntaxNode*) parse:(TCLexicalScanner*)scanner;
{
    return [self parse:scanner options:TCSTATEMENT_NONE];
}


-(TCSyntaxNode*) parse:(TCLexicalScanner*)scanner options:(TCStatementOptions) options
{
    TCSyntaxNode * tree = nil;
    
    // See if this is an empty statement
    
    if([scanner isNextToken:TOKEN_SEMICOLON])
        return nil;
    
    // See if this is a basic block
    
    if( [scanner isNextToken:TOKEN_BRACE_LEFT]) {
        //NSLog(@"PARSE Basic block");
        
        tree = [TCSyntaxNode node:LANGUAGE_BLOCK usingScanner:scanner];
        tree.position = scanner.tokenPosition;
        
        while(1) {
            if([scanner isNextToken:TOKEN_BRACE_RIGHT])
                break;
            
            TCSyntaxNode * stmt = [self parse:scanner];
            if( scanner.error != nil)
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
        if([scanner isNextToken:TOKEN_CONTINUE]) {
            TCSyntaxNode * stmt = [TCSyntaxNode node:LANGUAGE_CONTINUE usingScanner:scanner];
            stmt.position = scanner.tokenPosition;
            return stmt;
        }
    }
    
    // BREAK
    if( tree == nil ) {
        if([scanner isNextToken:TOKEN_BREAK]) {
            TCSyntaxNode * stmt = [TCSyntaxNode node:LANGUAGE_BREAK usingScanner:scanner];
            stmt.position = scanner.tokenPosition;
            return stmt;
        }
    }
    // RETURN
    if( tree == nil ) {
        if( [scanner isNextToken:TOKEN_RETURN]) {
            long mark = scanner.position;
            TCExpressionParser * expr = nil;
            TCSyntaxNode * ret = [TCSyntaxNode node:LANGUAGE_RETURN usingScanner:scanner];
            ret.position = scanner.tokenPosition;
            
            if( [scanner nextToken] != TOKEN_SEMICOLON) {
                scanner.position = mark;
                expr = [[TCExpressionParser alloc]init];
            ret.subNodes = [NSMutableArray arrayWithArray:@[[expr parse:scanner]]];
            }
            else
                scanner.position = mark;
            
            if(scanner.error)
                return nil;
            return ret;
        }
    }
    
    // DECLARATION
    
    if( tree == nil ) {
        TCDeclarationParser * declaration = [[TCDeclarationParser alloc] init];
        tree = [declaration parse:scanner];
        if( scanner.error != nil) {
            return nil;
        }
    }
    
    // ASSIGNMENT
    if( tree == nil ) {
        
        TCAssignmentParser * assignment = [[TCAssignmentParser alloc] init];
        tree = [assignment parse:scanner];
        if( scanner.error != nil ) {
            return nil;
        }
    }
    
    // FOR
    if( tree == nil ) {
        
        long savedPosition = scanner.position;
        if([scanner isNextToken:TOKEN_FOR]) {
            long tokenPosition = scanner.tokenPosition;
            
            if([scanner isNextToken:TOKEN_PAREN_LEFT]) {
                
                // There are three statement groups separated by ";" characters
                scanner.error = nil;
                TCStatementParser * clause = [[TCStatementParser alloc]init];
                TCSyntaxNode * initClause = nil;
                TCSyntaxNode * termClause = nil;
                TCSyntaxNode * incrementClause = nil;
                TCSyntaxNode * block = nil;
                
                // Initialization
                initClause = [clause parse:scanner options:TCSTATEMENT_NONE];
                if( initClause == nil || scanner.error) {
                    tree = nil;
                }
                else {
                    termClause = [clause parse:scanner options:TCSTATEMENT_NONE];
                    if( termClause == nil || scanner.error) {
                        tree = nil;
                    }
                    else {
                        incrementClause = [clause parse:scanner options:TCSTATEMENT_SUBSTATEMENT];
                        if( incrementClause == nil || scanner.error) {
                            tree = nil;
                        }
                        else {
                            if( ![scanner isNextToken:TOKEN_PAREN_RIGHT]) {
                                scanner.error = [[TCError alloc]initWithCode:TCERROR_PARENMISMATCH usingScanner:scanner];
                            } else {
                                block = [clause parse:scanner options:TCSTATEMENT_NONE];
                                if( block == nil || scanner.error) {
                                    tree = nil;
                                } else {
                                    tree = [TCSyntaxNode node:LANGUAGE_FOR usingScanner:scanner];
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
            scanner.position = savedPosition;
        }
    }
    
    // WHILE
    // Note that this is really the same a FOR but without an initializer or increment clause.
    if( tree == nil ) {
        
        long savedPosition = scanner.position;
        if([scanner isNextToken:TOKEN_WHILE]) {
            long tokenPosition = scanner.tokenPosition;
            
            if([scanner isNextToken:TOKEN_PAREN_LEFT]) {
                
                // There is a single term clause and a body to process
                scanner.error = nil;
                TCStatementParser * clause = [[TCStatementParser alloc]init];
                TCSyntaxNode * termClause = nil;
                TCSyntaxNode * block = nil;
                
                termClause = [clause parse:scanner options:TCSTATEMENT_SUBSTATEMENT];
                if( termClause == nil || scanner.error) {
                    tree = nil;
                }
                else {
                    if( ![scanner isNextToken:TOKEN_PAREN_RIGHT]) {
                        scanner.error = [[TCError alloc]initWithCode:TCERROR_PARENMISMATCH usingScanner:scanner];
                    } else {
                        block = [clause parse:scanner options:TCSTATEMENT_NONE];
                        if( block == nil || scanner.error) {
                            tree = nil;
                        } else {
                            tree = [TCSyntaxNode node:LANGUAGE_WHILE usingScanner:scanner];
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
            scanner.position = savedPosition;
        }
    }
    
    // IF [ELSE]
    if( tree == nil ) {
        TCIfParser * ifStatement = [[TCIfParser alloc] init];
        tree = [ifStatement parse:scanner];
        if( scanner.error != nil) {
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
        tree = [exp parse:scanner];
        if( scanner.error != nil) {
            return nil;
        }
    }
    
    if(tree != nil) {
        if(!(options & TCSTATEMENT_SUBSTATEMENT)) {
            // NSLog(@"PARSE require ';'");
            
            if(![scanner isNextToken:TOKEN_SEMICOLON]) {
                
                [scanner error:TCERROR_SEMICOLON];
                return nil;
                
            }
        }
        
        return tree;
    }
    
    scanner.error = [[TCError alloc]initWithCode:TCERROR_UNK_STATEMENT usingScanner:scanner withArgument:[scanner lastSpelling]];
    return nil;
}

@end
