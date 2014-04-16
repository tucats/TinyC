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

-(TCSyntaxNode*) parse:(TCParser*)parser
{
    TCSyntaxNode * decl = [[TCSyntaxNode alloc]init];
    long savedPosition = parser.position;
    
    if( [parser isNextToken:TOKEN_DECL_INT] ||
       [parser isNextToken:TOKEN_DECL_DOUBLE]) {
        
        decl = [[TCSyntaxNode alloc]init];
        decl.nodeType = LANGUAGE_TYPE;
        decl.action = TCVALUE_UNDEFINED;
        
        // Check for builtin types first.
        switch(parser.lastTokenType) {
            case TOKEN_DECL_DOUBLE:
                decl.action = TCVALUE_DOUBLE;
                break;
                
            case TOKEN_DECL_INT:
                decl.action = TCVALUE_INT;
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
            if([parser isNextToken:TOKEN_MULTIPLY]) {
                TCSyntaxNode * ptrData = [[TCSyntaxNode alloc]init];
                ptrData.nodeType = LANGUAGE_ADDRESS;
                decl.subNodes = [NSMutableArray arrayWithArray:@[ptrData]];
            }
        }
        
        // At this point, if we do not know what the type is, it wasn't a
        // type declaration after all and we bail out, resetting the parser.
        
        if( decl.action == TCVALUE_UNDEFINED) {
            parser.position = savedPosition;
            return nil;
        }
        return decl;
    }
    return nil;
}
@end
