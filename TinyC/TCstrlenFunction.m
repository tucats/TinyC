//
//  TCstrlenFunction.m
//  TinyC
//
//  Created by Tom Cole on 4/6/15.
//  Copyright (c) 2015 Forest Edge. All rights reserved.
//

#import "TCstrlenFunction.h"

@implementation TCstrlenFunction

-(TCValue*) execute:(NSArray *)arguments inContext:(TCExecutionContext*) context
{
    
    if( arguments.count != 1 ) {
        self.error = [[TCError alloc]initWithCode:TCERROR_ARG_MISMATCH atNode:nil];
        return nil;
    }
    
    TCValue * strArg = arguments[0];
    long strAddress = strArg.getLong;

    long count = 0;
    while(true) {
        char ch = [self.storage getChar:strAddress+count];
        if( ch == 0 )
            break;
        count++;
    }
    return [[TCValue alloc]initWithLong:count];
}
@end
