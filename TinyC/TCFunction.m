//
//  TCFunction.m
//  TinyC
//
//  Created by Tom Cole on 4/18/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCFunction.h"

@implementation TCFunction

-(TCValue*) execute:(NSArray*) arguments
{
    NSLog(@"FATAL - attempt to execute abstract function");
    return nil;
}

@end
