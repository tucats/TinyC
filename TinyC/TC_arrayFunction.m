//
//  TC_arrayFunction.m
//  TinyC
//
//  Created by Tom Cole on 4/18/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TC_arrayFunction.h"
#import "TCToken.h"

@implementation TC_arrayFunction

-(TCValue*) execute:(NSArray *)arguments inContext:(TCExecutionContext*) context
{
    
    // There must be two arguments
    if( arguments.count != 2 ) {
        self.error = [[TCError alloc]initWithCode:TCERROR_ARG_MISMATCH atNode:nil];
        return nil;
    }
    
    TCValue * v = arguments[1];
    int t = (int)v.getLong;
    int size;
    switch( t ) {
        case TOKEN_DECL_CHAR:
        case TCVALUE_CHAR:
            size = 1;
            t = TCVALUE_CHAR;
            break;
        case TOKEN_DECL_INT:
        case TCVALUE_INT:
            size = sizeof(int);
            t = TCVALUE_INT;
            break;
        case TOKEN_DECL_LONG:
        case TCVALUE_LONG:
           size = sizeof(long);
            t = TCVALUE_LONG;
            break;
        case TOKEN_DECL_DOUBLE:
        case TCVALUE_DOUBLE:
            size = sizeof(double);
            t = TCVALUE_DOUBLE;
            break;
        case TOKEN_DECL_FLOAT:
        case TCVALUE_FLOAT:
            size = sizeof(float);
            t = TCVALUE_FLOAT;
            break;

        default:
            size = 1;
            t = TCVALUE_CHAR;
    }
    v = arguments[0];
    long count = v.getLong;
    
    // Now that we have a size*count, allocate some space in automatic storage
    // that is aligned to our natural storage size.
    
    [self.storage align:size];
    long address = [self.storage allocUnpadded:(count * size)];
    return [[[TCValue alloc] initWithLong:address] makePointer:t];
    
}
@end
