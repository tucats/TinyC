//
//  TCStorage.h
//  TinyC
//
//  Created by Tom Cole on 4/14/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCValue.h"

@interface TCStorage : NSObject

@property char * buffer;
@property long base;
@property long current;
@property NSMutableArray * stack;
@property long size;
@property BOOL debug;
@property int frameCount;

-(instancetype) initWithStorage:(long) size;
-(long) pushStorage;
-(long) popStorage;
-(long) alloc:(long)size;
-(long) allocUnpadded:(long)size;

-(TCValue*) getValue:(long) address ofType:(TCValueType) type;
-(void) setValue:(TCValue*) value at:(long) address;

-(char) getChar:(long) address;
-(void) setChar:(char) value at:(long) address;

-(int) getInt:(long) address;
-(void) setInt:(int) value at:(long) address;

-(double) getDouble:(long) address;
-(void) setDouble:(double) value at:(long) address;
@end
