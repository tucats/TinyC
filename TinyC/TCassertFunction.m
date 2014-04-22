//
//  TCassertFunction.m
//  TinyC
//
//  Created by Tom Cole on 4/22/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCassertFunction.h"

@implementation TCassertFunction

extern BOOL assertAbort;

-(TCValue*) execute:(NSArray *)arguments
{
    
    if( arguments.count != 2 ) {
        self.error = [[TCError alloc]initWithCode:TCERROR_ARG_MISMATCH withArgument:nil];
        return nil;
    }
    
    if( !assertAbort )
        return [[TCValue alloc]initWithInt:0];

    TCValue * sizeArg = arguments[0];
    long test = sizeArg.getLong;
    
    if( test )
        return [[TCValue alloc]initWithInt:0];
    
    if( !assertAbort )
        return [[TCValue alloc]initWithInt:1];

    TCValue * msg = arguments[1];
    NSString *msgText = nil;
    
    if( msg.getType == TCVALUE_CHAR + TCVALUE_POINTER)
        msgText = [self.storage getString:msg.getLong];
    else
        msgText = msg.getString;
        
    NSLog(@"ASSERT: %@", msgText);
    exit(-99);
    
    return nil;
    
}


@end
