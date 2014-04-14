//
//  TCStorage.m
//  TinyC
//
//  Created by Tom Cole on 4/14/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCStorage.h"
#import "TCValue.h"

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
        _debug = NO;
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
    if(_debug)
        NSLog(@"STORAGE: push new storage frame at %ld", _current);
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
    if(_debug)
        NSLog(@"STORAGE: pop old storage frame at %ld", _current);

    return _base;
}

-(long) alloc:(long)size
{
    if( _current + size > _size) {
        NSLog(@"Memory exhausted");
        return 0L;
    }
    if(_debug)
        NSLog(@"STORAGE: alloc %ld bytes at %ld", size,  _current);

    long newAddr = _current;
    _current += size;
    return newAddr;
}

#pragma mark - Memmory Accessors

-(TCValue*) getValue:(long)address ofType:(TCValueType) type
{
    
    TCValue * v = nil;
    if(_debug)
        NSLog(@"STORAGE: Access value of type %d at %ld", type, address);

    switch(type) {
        case TCVALUE_DOUBLE:
            v = [[TCValue alloc]initWithDouble:[self getDouble:address]];
            break;
    
        case TCVALUE_BOOLEAN:
        case TCVALUE_CHAR:
            v = [[TCValue alloc]initWithInteger:(long)[self getChar:address]];
            break;
            
        case TCVALUE_INT:
            v = [[TCValue alloc]initWithInteger:(long)[self getInt:address]];
            break;
            
        default:
            v = nil;
            break;
    }
    
    return v;
}
-(void) setValue:(TCValue *)value at:(long)address
{
    if(_debug)
        NSLog(@"STORAGE: store value %@ of type %d at %ld", value, value.getType, address);

    switch( value.getType) {
        case TCVALUE_INT:
            [self setInt:(int)value.getInteger at:address];
            break;
        case TCVALUE_LONG:
            [self setLong:value.getInteger at:address];
            break;
        case TCVALUE_DOUBLE:
            [self setDouble:value.getDouble at:address];
            break;
        case TCVALUE_CHAR:
            [self setChar:value.getChar at:address];
    }
}

-(char) getChar:(long)address
{
    if( address < 0L || address > _current) {
        NSLog(@"Address fault %08lX", address);
        return 0;
    }
    if(_debug)
        NSLog(@"STORAGE: read char from %ld", address);

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
    if(_debug)
        NSLog(@"STORAGE: read int from %ld", address);
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


-(long) getLong:(long)address
{
    if( address < 0L || address > _current) {
        NSLog(@"Address fault %08lX", address);
        return 0;
    }
    if(_debug)
        NSLog(@"STORAGE: read long from %ld", address);

    return *(long*)&( _buffer[address]);
}

-(void) setLong:(long)value at:(long)address
{
    if( address < 0L || address > _current) {
        NSLog(@"Address fault %08lX", address);
        return;
    }
    *(long*)&( _buffer[address]) = value;
}

-(double) getDouble:(long)address
{
    if( address < 0L || address > _current) {
        NSLog(@"Address fault %08lX", address);
        return 0.0;
    }
    if(_debug)
        NSLog(@"STORAGE: read double from %ld", address);

   return *(double*)&( _buffer[address]);
}


-(void) setDouble:(double) value at:(long)address
{
    if( address < 0L || address > _current) {
        NSLog(@"Address fault %08lX", address);
        return;
    }
    *(double*)&( _buffer[address]) = value = value;
}

@end
