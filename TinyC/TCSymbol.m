//
//  TCSymbol.m
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import "TCSymbol.h"
#import "TCStorage.h"

@implementation TCSymbol

/**
 This is the designated initializer
 
 Create a new symbol node.
 
 @param name the name of the symbol
 @param type the symbol type (SYMBOL_INTEGER, SYMBOL_POINTER, etc.)
 @param size the symbol size or offset value
 @returns the newly created node.
 */
-(instancetype) initWithName:(NSString*) name withType:(TCValueType) type withSize:(int) size
{
    if((self = [super init])){
        
        _spelling = name;
        _type = type;
        _size = size;
        _initialValue = nil;
        _allocated = NO;
        _address = -1L;
    }
    
    return self;
}

-(void) setValue:(TCValue*)value storage:(TCStorage*) storage
{
    _initialValue = value;
    if( _allocated )
        [storage setValue:value at:_address];
    else
        NSLog(@"FATAL: attempt to store value with no storage allocated");
    
}
-(NSString*)description
{
    NSMutableString * d = [NSMutableString string];
    
    [d appendFormat:@"\"%@\" ", self.spelling];
    BOOL isPointer = NO;
    
    TCValueType t = self.type;
    if( t > TCVALUE_POINTER) {
        isPointer = YES;
        t = t - TCVALUE_POINTER;
    }
    switch( t ) {
        case TCVALUE_INT:
        case TCVALUE_LONG:
            [d appendFormat:@" integer*%d ", self.size];
            break;
            
        case TCVALUE_FLOAT:
        case TCVALUE_DOUBLE:
            [d appendFormat:@" double*%d ", self.size];
            break;
            
        case TCVALUE_STRING:
            [d appendFormat:@" string*%d ", self.size];
            break;
        
        case TCVALUE_POINTER:
            [d appendFormat:@" void "];
            isPointer = YES;
            break;
            
        default:
            [d appendFormat:@" unknown type %d ", t];
            
    }
    
    if( isPointer)
        [d appendString:@" pointer "];
    
    if( _allocated)
        [d appendString:[NSString stringWithFormat:@" @%ld", _address]];
    return [NSString stringWithString:d];
}


@end
