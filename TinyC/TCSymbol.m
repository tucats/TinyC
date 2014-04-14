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
-(instancetype) initWithName:(NSString*) name withType:(TCSymbolType) type withSize:(int) size
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
    
}
-(NSString*)description
{
    NSMutableString * d = [NSMutableString string];
    
    [d appendFormat:@"\"%@\" ", self.spelling];
    
    switch( self.type ) {
        case SYMBOL_INTEGER:
            [d appendFormat:@" integer*%d ", self.size];
            break;
            
        case SYMBOL_FLOAT:
            [d appendFormat:@" double*%d ", self.size];
            break;
        case SYMBOL_STRING:
            [d appendFormat:@" string*%d ", self.size];
            break;
            
        default:
            [d appendString:@" unknown type "];
            
    }
    return [NSString stringWithString:d];
}


@end
