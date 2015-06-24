//
//  TCStorage.h
//  TinyC
//
//  Created by Tom Cole on 4/14/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCValue.h"

@interface TCStorageManager : NSObject

{
    NSMutableArray * _freeList;
    NSMutableArray * _allocList;
    NSMutableArray * _stringPool;
    NSMutableArray * _stringAddress;
    
}
@property char * buffer;
@property long base;
@property long current;
@property NSMutableArray * stack;
@property long size;
@property BOOL debug;
@property int frameCount;
@property long dynamic;

@property long autoMark;
@property long dynamicMark;
@property long maxFrames;


-(instancetype) initWithStorage:(long) size;
-(long) pushStorage;
-(long) popStorage;
-(long) allocateAuto:(long)size;
-(long) allocateDynamic:(long)size;
-(long) allocUnpadded:(long)size;
-(long) free:(long) address;
-(void) align:(long)size;

-(BOOL) isFault:(long) address;
-(TCValue*) getValue:(long) address ofType:(TCValueType) type;
-(void) setValue:(TCValue*) value at:(long) address;

-(char) getChar:(long) address;
-(void) setChar:(char) value at:(long) address;

-(int) getInt:(long) address;
-(void) setInt:(int) value at:(long) address;

-(long) getLong:(long) address;
-(void) setLong:(long) value at:(long) address;

-(double) getDouble:(long) address;
-(void) setDouble:(double) value at:(long) address;

-(NSString*) getString:(long)address;

-(TCValue*) allocateString: (NSString*) string;
@end
