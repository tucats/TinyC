//
//  TCFunction.h
//  TinyC
//
//  Created by Tom Cole on 4/18/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCValue.h"
#import "TCStorage.h"
#import "TCError.h"

@interface TCFunction : NSObject

@property TCStorage *storage;
@property TCError *error;

-(TCValue*) execute:(NSArray*) arguments;

@end
