//
//  TCrandomFunction.m
//  TinyC
//
//  Created by Tom Cole on 5/1/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCrandomFunction.h"

@implementation TCrandomFunction


-(TCValue*) execute:(NSArray *)arguments inContext:(TCExecutionContext*) context
{
    
    if( arguments.count != 0 ) {
        self.error = [[TCError alloc]initWithCode:TCERROR_ARG_MISMATCH
                                           atNode:nil
                                     withArgument:nil];
        return nil;
    }
    
    return [[TCValue alloc]initWithLong:random()];
    
}

@end
