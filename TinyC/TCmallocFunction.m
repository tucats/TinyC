//
//  TCmallocFunction.m
//  TinyC
//
//  Created by Tom Cole on 4/18/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCmallocFunction.h"

@implementation TCmallocFunction

-(TCValue*) execute:(NSArray *)arguments inContext:(TCExecutionContext*) context
{
    
        if( arguments.count != 1 ) {
            self.error = [[TCError alloc]initWithCode:TCERROR_ARG_MISMATCH atNode:nil];
            return nil;
        }
        
        TCValue * sizeArg = arguments[0];
        long size = sizeArg.getLong;
        
        long address = [self.storage allocateDynamic:size];
        TCValue * addressPtr = [[TCValue alloc]initWithLong:address];
        return [addressPtr makePointer:TCVALUE_CHAR];
}
@end
