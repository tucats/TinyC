//
//  TCStorage.m
//  TinyC
//
//  Created by Tom Cole on 4/14/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCStorage.h"
#import "TCValue.h"

const char * typeName( TCValueType t )
{
    NSMutableString * name = [NSMutableString string];
    static char msgBuffer[80];
    
    TCValueType lt = t;
    if( lt > TCVALUE_POINTER) {
        [name appendString:@"TCVALUE_POINTER+"];
        lt = lt - TCVALUE_POINTER;
    }
    switch(lt) {
        case TCVALUE_BOOLEAN:
            [name appendString:@"TCVALUE_BOOLEAN"];
            break;
            
        case TCVALUE_CHAR:
            [name appendString: @"TCVALUE_CHAR"];
            break;
            
        case TCVALUE_DOUBLE:
            [name appendString: @"TCVALUE_DOUBLE"];
            break;
            
        case TCVALUE_FLOAT:
            [name appendString: @"TCVALUE_FLOAT"];
            break;
            
        case TCVALUE_INT:
            [name appendString: @"TCVALUE_INT"];
            break;
            
        case TCVALUE_LONG:
            [name appendString: @"TCVALUE_LONG"];
            break;
            
        case TCVALUE_POINTER:
            [name appendString: @"TCVALUE_POINTER"];
            break;
            
        case TCVALUE_STRING:
            [name appendString: @"TCVALUE_STRING!!!"];
            break;
            
        case TCVALUE_UNDEFINED:
            [name appendString: @"TCVALUE_UNDEFINED!!!"];
            break;
            
        default:
            return "undefined type";
    }
    [name getCString:msgBuffer maxLength:78 encoding:NSUTF8StringEncoding];
    return msgBuffer;
}
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
    _frameCount++;
    if(_debug)
        NSLog(@"STORAGE: push new storage frame #%d at %ld", _frameCount, _current);
    [_stack addObject:[NSNumber numberWithLong:_base]];
    [_stack addObject:[NSNumber numberWithLong:_current]];
    _base = _current;
    return _base;
}

-(long) popStorage
{
    if( _frameCount < 0 ) {
        NSLog(@"STORAGE: FATAL, too many stack frames popped");
        return 0;
    }
    long idx =_stack.count-1;
    long frameSize = _current - _base;
    
    NSNumber *oldCurrent = [_stack objectAtIndex:idx];
    NSNumber *oldBase = [_stack objectAtIndex:idx];
    _base = oldBase.longValue;
    _current = oldCurrent.longValue;
    
    [_stack removeObjectAtIndex:idx];
    if(_debug)
        NSLog(@"STORAGE: pop old storage frame #%d at %ld, discarding %ld bytes", _frameCount, _current, frameSize);
    _frameCount--;
    return _base;
}


-(long) allocUnpadded:(long)size
{
    if( _current + size > _size) {
        NSLog(@"Memory exhausted");
        return 0L;
    }
    
    // Do the allocation
    
    if(_debug)
        NSLog(@"STORAGE: alloc %ld bytes at %ld", size,  _current);
    
    long newAddr = _current;
    _current += size;
    return newAddr;
}


-(long) alloc:(long)size
{
    if( _current + size > _size) {
        NSLog(@"Memory exhausted");
        return 0L;
    }
    
    // Adjust the pointer to be a multiple of the storage size
    
    long pad = _current % size;
    if( pad ) {
        _current = _current + (size-pad);
        if(_debug)
            NSLog(@"STORAGE: allocation padded by %d bytes", (int)(size-pad));
    }
    // Do the allocation
    
    if(_debug)
        NSLog(@"STORAGE: alloc %ld bytes at %ld", size,  _current);
    
    long newAddr = _current;
    _current += size;
    return newAddr;
}

#pragma mark - Memory Accessors

-(TCValue*) getValue:(long)address ofType:(TCValueType) type
{
    
    TCValue * v = nil;
    if(_debug)
        NSLog(@"STORAGE: Access value of type %s at %ld", typeName(type), address);
    
    switch(type) {
        case TCVALUE_DOUBLE:
            v = [[TCValue alloc]initWithDouble:[self getDouble:address]];
            break;
            
        case TCVALUE_BOOLEAN:
        case TCVALUE_CHAR:
            v = [[TCValue alloc]initWithInt:(int)[self getChar:address]];
            break;
            
        case TCVALUE_INT:
            v = [[TCValue alloc]initWithInt:(int)[self getInt:address]];
            break;
            
        default:
            v = nil;
            break;
    }
    
    return v;
}

/**
 Given a TCValue object, store it in the virtual memory area.  This can be a pointer (in
 which case use the long value as it contains the underlying address) or it can be a
 scalar object where the specific data type is written into storage.
 
 @param value the TCValue containing data to be written
 @param address the virtual address to write the data to
 */

-(void) setValue:(TCValue *)value at:(long)address
{
    if(_debug)
        NSLog(@"STORAGE: store value %@ of type %s at %ld", value, typeName(value.getType), address);
    
    if( value.getType >= TCVALUE_POINTER )
        [self setLong:value.getLong at:address];
    else {
        switch( value.getType) {
            case TCVALUE_INT:
                [self setInt:(int)value.getInt at:address];
                break;
            case TCVALUE_LONG:
                [self setLong:value.getLong at:address];
                break;
            case TCVALUE_DOUBLE:
                [self setDouble:value.getDouble at:address];
                break;
            case TCVALUE_CHAR:
                [self setChar:value.getChar at:address];
                
            default:
                NSLog(@"FATAL - storage setValue type %s %d not implemented", typeName(value.getType), value.getType);
        }
    }
}

-(char) getChar:(long)address
{
    if( address < 0 || address >= _current) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return 0;
    }
    char result = _buffer[address];
    if(_debug)
        NSLog(@"STORAGE: read char %d from %ld", result, address);
    
    return result;
}

-(void) setChar:(char)value at:(long)address
{
    if( address < 0 || address >= _current) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return;
    }
    _buffer[address] = value;
}

-(int) getInt:(long)address
{
    if( address < 0 || address >= _current) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return 0;
    }
    int result = *((int*)(&( _buffer[address])));
    if(_debug)
        NSLog(@"STORAGE: read int %d from %ld", result, address);
    return result;
}

-(void) setInt:(int)value at:(long)address
{
    if( address < 0 || address >= _current) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return;
    }
    *(int*)&( _buffer[address]) = value;
}


-(long) getLong:(long)address
{
    if( address < 0 || address >= _current) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return 0;
    }
    long result = *(long*)&( _buffer[address]);
    if(_debug)
        NSLog(@"STORAGE: read long %ld from %ld", result, address);
    
    return result;
}

-(void) setLong:(long)value at:(long)address
{
    if( address < 0 || address >= _current) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return;
    }
    *(long*)&( _buffer[address]) = value;
}

-(double) getDouble:(long)address
{
    if( address < 0 || address >= _current) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return 0.0;
    }
    double result = *(double*)&( _buffer[address]);
    if(_debug)
        NSLog(@"STORAGE: read double %f from %ld", result, address);
    
    return result ;
}


-(void) setDouble:(double) value at:(long)address
{
    if( address < 0 || address >= _current) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return;
    }
    *(double*)&( _buffer[address]) = value = value;
}

-(NSString*) getString:(long)address
{
    NSMutableString * result = [NSMutableString string];
    for( long ix = address; ix < _current; ix++ ) {
        char ch = _buffer[ix];
        [result appendFormat:@"%c", ch];
        if( ch == 0 )
            break;
    }
    return [NSString stringWithString:result];
}
@end
