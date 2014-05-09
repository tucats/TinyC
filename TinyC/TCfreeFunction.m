//
//  TCfreeFunction.m
//  TinyC
//
//  Created by Tom Cole on 4/18/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCfreeFunction.h"

@implementation TCfreeFunction

-(TCValue*) execute:(NSArray *)arguments inContext:(TCExecutionContext*) context
{
    if( arguments.count != 1 ) {
        self.error = [[TCError alloc]initWithCode:TCERROR_ARG_MISMATCH atNode:nil];
        return nil;
    }
    
    TCValue * addrV = arguments[0];
    long addr = addrV.getLong;
    return [[TCValue alloc]initWithLong:[self.storage free:addr]];
}
@end
