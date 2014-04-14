//
//  TCStorage.m
//  TinyC
//
//  Created by Tom Cole on 4/14/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCStorage.h"

@implementation TCStorage

#pragma mark - Initialization

-(instancetype) init {
    return [self initWithStorage:65536];
}

-(instancetype) initWithStorage:(long) size
{
    
    if(( self = [super init])) {
        _buffer = malloc(size);
        if(! _buffer ) {
            return nil;
        }
        _size = size;
        _base = 0L;
        _current = _base;
        _stack = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Dynamic Sizing

-(long) pushStorage;
{
    [_stack addObject:[NSNumber numberWithLong:_base]];
    _base = _current;
    return _base;
}

-(long) popStorage
{
    if( _stack.count == 0 )
        return 0;
    long idx =_stack.count-1;
    
    NSNumber *oldBase = [_stack objectAtIndex:idx];
    _base = _current = oldBase.longValue;
    
    [_stack removeObjectAtIndex:idx];
    return _base;
}

-(long) alloc:(long)size
{
    if( _current + size > _size) {
        NSLog(@"Memory exhausted");
        return 0L;
    }
    
    long newAddr = _current;
    _current += size;
    return newAddr;
}

#pragma mark - Memmory Accessors
-(char) getChar:(long)address
{
    if( address < 0L || address > _current) {
        NSLog(@"Address fault %08lX", address);
        return 0;
    }
    return _buffer[address];
}
-(void) setChar:(char)value at:(long)address
{
    if( address < 0L || address > _current) {
        NSLog(@"Address fault %08lX", address);
        return;
    }
    _buffer[address] = value;
}

-(int) getInt:(long)address
{
    if( address < 0L || address > _current) {
        NSLog(@"Address fault %08lX", address);
        return 0;
    }
    return *(int*)&( _buffer[address]);
}

-(void) setInt:(int)value at:(long)address
{
    if( address < 0L || address > _current) {
        NSLog(@"Address fault %08lX", address);
        return;
    }
    *(int*)&( _buffer[address]) = value;
}

@end
