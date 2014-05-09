//
//  TCTypeParser.m
//  TinyC
//
//  Created by Tom Cole on 4/16/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCTypeParser.h"
#import "TCToken.h"
#import "TCValue.h"

@implementation TCTypeParser

-(TCSyntaxNode*) parse:(TCLexicalScanner*)scanner
{
    TCSyntaxNode * decl = nil;
    long savedPosition = scanner.position;
    
    if([scanner isNextToken:TOKEN_DECL_INT] ||
       [scanner isNextToken:TOKEN_DECL_LONG] ||
       [scanner isNextToken:TOKEN_DECL_DOUBLE] ||
       [scanner isNextToken:TOKEN_DECL_CHAR]) {
        
        decl = [TCSyntaxNode node:LANGUAGE_TYPE usingScanner:scanner];
        decl.action = TCVALUE_UNDEFINED;
        decl.position = scanner.tokenPosition;
        
        
        // Check for builtin types first.
        switch(scanner.lastTokenType) {
            case TOKEN_DECL_DOUBLE:
                decl.action = TCVALUE_DOUBLE;
                break;
                
            case TOKEN_DECL_INT:
                decl.action = TCVALUE_INT;
                break;
 
            case TOKEN_DECL_LONG:
                decl.action = TCVALUE_LONG;
                break;
                
            case TOKEN_DECL_CHAR:
                decl.action = TCVALUE_CHAR;
                break;
                
            default:
                decl.action = TCVALUE_UNDEFINED;
                
        }
        
        // Check for user types.
        if( decl.action == TCVALUE_UNDEFINED) {
            // Currently not implemented.
        }
        
        // If we have a type then see if it is a pointer to that type
        
        if( decl.action != TCVALUE_UNDEFINED) {
            if([scanner isNextToken:TOKEN_ASTERISK]) {
                TCSyntaxNode * ptrData = [TCSyntaxNode node:LANGUAGE_ADDRESS usingScanner:scanner];
                ptrData.position = scanner.tokenPosition;
                
                decl.subNodes = [NSMutableArray arrayWithArray:@[ptrData]];
            }
        }
        
        // At this point, if we do not know what the type is, it wasn't a
        // type declaration after all and we bail out, resetting the parser.
        
        if( decl.action == TCVALUE_UNDEFINED) {
            scanner.position = savedPosition;
            return nil;
        }
        return decl;
    }
    return nil;
}
@end
