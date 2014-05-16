//
//  TCSymbol.m
//  TinyC
//
//  Created by Tom Cole on 5/15/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCSymbol.h"
#import "TCSymbolTable.h"

// This array must match the order of the
// enumerated TCSymbolAttribute base types.

static int baseTypeDataSizes[] = {
    0,              // TC_SYMBOL_UNDEFINED
    sizeof(char),   // TC_SYMBOL_CHAR
    sizeof(int),    // TC_SYMBOL_INT
    sizeof(long),   // TC_SYMBOL_LONG
    sizeof(float),  // TC_SYMBOL_FLOAT
    sizeof(double), // TC_SYMBOL_DOUBLE
    -1 };           // TC_SYMBOL_TYPEDEF


@implementation TCSymbol

+(instancetype) symbolWithName:(NSString *)name withAttributes:(TCSymbolAttribute)attributes containedBy:(TCSymbol *)parent
{
    return [[self alloc] initWithName:name withAttributes:attributes containedBy:parent];
}

/**
 Initialize a new symbol object. The object is assumed not to have a container.
 
 @param name        The name of the symbol to create
 @param attributes  The attributes of the symbol
 */

-(instancetype) initWithName:(NSString *)name withAttributes:(TCSymbolAttribute)attributes
{
    return [self initWithName:name withAttributes:attributes containedBy:nil];
}

/**
 Initialize a new symbol object.
 
 @param name        The name of the symbol to create
 @param attributes  The attributes of the symbol
 @param parent      The container symbol, or nil if this symbol has no container
 */
-(instancetype) initWithName:(NSString *)name withAttributes:(TCSymbolAttribute)attributes containedBy:(TCSymbol *)parent
{
    if((self=[super init])) {
        
        _name = name;
        _attributes = attributes;
        _parent = parent;
        _table = nil;
        _size = baseTypeDataSizes[BASETYPE(attributes)];
        
    }
    
    return self;
}
@end
