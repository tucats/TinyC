//
//  TCFunction.h
//  TinyC
//
//  Created by Tom Cole on 4/18/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCValue.h"
#import "TCStorageManager.h"
#import "TCExecutionContext.h"
#import "TCError.h"

@interface TCFunction : NSObject

@property TCStorageManager *storage;
@property TCError *error;

-(TCValue*) execute:(NSArray*) arguments inContext:(TCExecutionContext*) context;

@end
