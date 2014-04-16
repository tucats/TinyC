//
//  TCStatement.m
//  Language
//
//  Created by Tom Cole on 4/7/14.
//
//

#import "TCStatement.h"
#import "TCDeclarationParser.h"
#import "TCAssignmentParser.h"
#import "TCExpressionParser.h"
#import "TCIfParser.h"

@implementation TCStatement

/**
 Helper function that doesn't require options - assumes none are given
 */
-(TCSyntaxNode*) parse:(TCParser*)parser error:(TCError**)error;
{
    return [self parse:parser error:error options:TCSTATEMENT_NONE];
}


-(TCSyntaxNode*) parse:(TCParser*)parser error:(TCError**)error options:(TCStatementOptions) options
{
    TCSyntaxNode * tree = nil;
    
    // See if this is an empty statement
    
    if([parser isNextToken:TOKEN_SEMICOLON])
        return nil;
    
    // See if this is a basic block
    
    if( [parser isNextToken:TOKEN_OPEN_BRACE]) {
        //NSLog(@"PARSE Basic block");
        
        tree = [[TCSyntaxNode alloc]init];
        tree.nodeType = LANGUAGE_BLOCK;
        
        while(1) {
            if([parser isNextToken:TOKEN_CLOSE_BRACE])
                break;
            
            TCSyntaxNode * stmt = [self parse:parser error:error];
            if( error != nil && (*error != nil) )
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
    
    // RETURN
    if( tree == nil ) {
        if( [parser isNextToken:TOKEN_RETURN]) {
            TCExpressionParser * expr = [[TCExpressionParser alloc]init];
            TCSyntaxNode * ret = [[TCSyntaxNode alloc]init];
            ret.nodeType = LANGUAGE_RETURN;
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
        if( parser.error != nil && error != nil) {
            *error = parser.error;
            return nil;
        }
    }
    
    // ASSIGNMENT
    if( tree == nil ) {
        
        TCAssignmentParser * assignment = [[TCAssignmentParser alloc] init];
        tree = [assignment parse:parser];
        if( parser.error != nil && error != nil) {
            *error = parser.error;
            return nil;
        }
    }
    
    // IF [ELSE]
    if( tree == nil ) {
        TCIfParser * ifStatement = [[TCIfParser alloc] init];
        tree = [ifStatement parse:parser];
        if( parser.error != nil && error != nil) {
            *error = parser.error;
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
        if( parser.error != nil && error != nil) {
            *error = parser.error;
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
    
    if( error != nil ) {
        *error = [[TCError alloc]initWithCode:TCERROR_UNK_STATEMENT withArgument:[parser lastSpelling]];
    }
    
    
    return tree;
}

@end
