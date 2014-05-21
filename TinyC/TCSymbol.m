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


-(instancetype) initWithName:(NSString *)name
              withAttributes:(TCSymbolAttribute)attributes
{
    return [self initWithName:name withAttributes:attributes containedBy:nil];
}


//  Helper function to initialize a new symbol with a known parent

-(instancetype) initWithName:(NSString *)name
              withAttributes:(TCSymbolAttribute)attributes
                 containedBy:(TCSymbol *)parent
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
