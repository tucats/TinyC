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
        
        // Allocate the space for all tinyc runtime memory.
        
        _buffer = malloc(size);
        if(! _buffer ) {
            return nil;
        }
        _debug = NO;
        
        // _size is the size of the entire virtual memory area
        // _dynamic starts at the end of that area and grows towards
        // zero as memory is allocated and freed dynamically by the
        // runtime malloc() and free() calls.
        _size = size;
        _dynamic = size - 4L;

        // The first 8 bytes are filled with 0xFF as a trap to help
        // locate uninitialized pointer references.  The base of
        // actual allocated storage starts at byte 8
        for( int i = 0; i < 8; i++)
            _buffer[i] = 0xFF;
        _base = 8L;
        _current = _base;
        
        // This is the stack frame; it keeps up with the automatic
        // storage allocations from the runtime for each call
        // frame, and can discard them as needed.
        
        _stack = [NSMutableArray array];
        
        // This is the list of storage items that have been
        // allocated by the user and then free'd, and area
        // available to re-issue as needed. Each entry
        // contains an NSRange indicating the start and
        // length of each allocation.
        
        _freeList = [NSMutableArray array];
        _allocList = [NSMutableArray array];

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

-(long) allocateDynamic:(long)size
{

    // First, search list of free'd allocations to see if
    // we already have one this size to give away.
    
    for( int ix = 0; ix < _freeList.count; ix++) {
        NSValue * v = [_freeList objectAtIndex:ix];
        NSRange r = v.rangeValue;
        
        if( r.length == size) {
            [_freeList removeObjectAtIndex:ix];
            [_allocList addObject:v];
            if(_debug) {
                NSLog(@"STORAGE: dynalloc %ld byte @ %ld free list #%d",
                      size, r.location, ix);
            }
            return r.location;
        }
    }
    
    // No, we must allocate anew from the storage area
    
    if( _dynamic - size <= _current) {
        NSLog(@"FATAL - dynamic memory exhausted");
        return 0L;
    }
    
    _dynamic = _dynamic - size;
    [_allocList addObject:[NSValue valueWithRange:NSMakeRange(_dynamic, size)]];
    if(_debug) {
        NSLog(@"STORAGE: dynalloc %ld byte @ %ld alloc list #%ld",
              size, _dynamic, _allocList.count-1);
    }

    return _dynamic;
}

/**
 Free previously allocated memory
 @param the address in virtual memory that was previously returned by an alloc() operation
 @returns the number of bytes freed
 */

-(long) free:(long) address
{
    // Search the allocation list to find the matching
    // allocation record.
    
    for( int ix = 0; ix < _allocList.count; ix++ ) {
        NSValue *v = _allocList[ix];
        NSRange r = v.rangeValue;
        
        if( r.location == address) {
            
            // Delete from the allocation list and put on free list
            [_allocList removeObjectAtIndex:ix];
            [_freeList addObject:v];
            
            if(_debug)
                NSLog(@"STORAGE: free %ld bytes at %ld",
                      r.length, r.location);
            return r.length;
            
        }
    }
    
    // Not an allocation we know about
    if(_debug)
        NSLog(@"STORAGE: attempt to free unallocated memory at %ld", address);
    return 0;
}

/**
 Force the storage to be aligned on the natural 'size' boundary.
 @param size the natural alignment size.  If the current
 storage boundary is already an even multiple of this size then
 no further action is taken. Othewise, the pointer to the next
 available storage is moved to match the required alignment, such
 that the next allocation will be properly aligned.
 */

-(void) align:(long)size
{
    // Adjust the pointer to be a multiple of the storage size
    
    long pad = _current % size;
    if( pad ) {
        _current = _current + (size-pad);
        if(_debug)
            NSLog(@"STORAGE: allocation padded by %d bytes", (int)(size-pad));
    }
}


-(long) allocateAuto:(long)size
{
    if( _current + size > _size) {
        NSLog(@"Memory exhausted");
        return 0L;
    }
    
    // Adjust the pointer to be a multiple of the storage size
    [self align:size];

    // Do the allocation
    
    if(_debug)
        NSLog(@"STORAGE: alloc %ld bytes at %ld", size,  _current);
    
    long newAddr = _current;
    _current += size;
    return newAddr;
}

-(BOOL) isFault:(long) address
{
   if( address < 0L || address > _size )
       return YES;
    if((address >= _current) && (address < _dynamic))
        return YES;
    return NO;
}

#pragma mark - Memory Accessors

-(TCValue*) getValue:(long)address ofType:(TCValueType) type
{
    
    TCValue * v = nil;
    if(_debug)
        NSLog(@"STORAGE: Access value of type %s at %ld", typeName(type), address);
    
    if( type > TCVALUE_POINTER) {
        v = [[TCValue alloc]initWithLong:[self getLong:address]];
    } else {
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
 
            case TCVALUE_LONG:
                v = [[TCValue alloc]initWithLong:[self getLong:address]];
                break;
                
            default:
                NSLog(@"FATAL: Attempt to read unsupported value type %d from storage", type);
                v = nil;
                break;
        }
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
            case TCVALUE_CHAR:
                [self setChar:value.getChar at:address];
                break;
            case TCVALUE_INT:
                [self setInt:(int)value.getInt at:address];
                break;
            case TCVALUE_LONG:
                [self setLong:value.getLong at:address];
                break;
            case TCVALUE_DOUBLE:
                [self setDouble:value.getDouble at:address];
                break;

            default:
                NSLog(@"FATAL - storage setValue type %s %d not implemented", typeName(value.getType), value.getType);
        }
    }
}

-(char) getChar:(long)address
{
    
    if([self isFault:address]) {
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
    if([self isFault:address]) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return;
    }
    _buffer[address] = value;
}

-(int) getInt:(long)address
{
    if([self isFault:address]) {
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
    if([self isFault:address]) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return;
    }
    *(int*)&( _buffer[address]) = value;
}


-(long) getLong:(long)address
{
    if([self isFault:address]) {
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
    if([self isFault:address]) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return;
    }
    *(long*)&( _buffer[address]) = value;
}

-(double) getDouble:(long)address
{
    if([self isFault:address]) {
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
    if([self isFault:address]) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return;
    }
    *(double*)&( _buffer[address]) = value = value;
}

-(NSString*) getString:(long)address
{
    if([self isFault:address]) {
        NSLog(@"Address fault %08lX, _current = %ld", address, _current);
        return nil;
    }
    
    NSMutableString * result = [NSMutableString string];
    for( long ix = address; ix < _size; ix++ ) {
        char ch = _buffer[ix];
        [result appendFormat:@"%c", ch];
        if( ch == 0 )
            break;
    }
    return [NSString stringWithString:result];
}
@end
