//
//  TCSymbol.h
//  TinyC
//
//  Created by Tom Cole on 5/15/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCSymbolTable;

typedef enum  {
    // Undefined symbol type
    TC_SYMBOL_UNDEFINED =   0,
    
    //  Base types.  These all fit within an 8-bit byte
    TC_SYMBOL_CHAR =        1,
    TC_SYMBOL_INT =         2,
    TC_SYMBOL_LONG =        3,
    TC_SYMBOL_FLOAT =       4,
    TC_SYMBOL_DOUBLE =      5,
    TC_SYMBOL_TYPEDEF =     6,

    //  Modifiers. Must all be bits above the base byte.
    TC_SYMBOL_STRUCT =      (1<<8),
    TC_SYMBOL_POINTER =     (1<<9),
    TC_SYMBOL_ARRAY =       (1<<10),
    TC_SYMBOL_OFFSET =      (1<<11),
    TC_SYMBOL_STATIC =      (1<<12),
    TC_SYMBOL_AUTO =        (1<<13),
    TC_SYMBOL_ENUM =        (1<<14)
} TCSymbolAttribute;

#define BASETYPE(t)  (t & 0x0FF)
#define MODIFIERS(t) (t & 0xFFFFFF00L)

@interface TCSymbol : NSObject

@property   NSString *          name;
@property   TCSymbolAttribute   attributes;
@property   TCSymbolTable *     table;
@property   long                address;        // This is the assigned address value or offset
@property   int                 size;           // size of this storage item
@property   TCSymbol *          parent;         // This is the container symbol (struct, etc.) if appropriate

+(instancetype) symbolWithName:(NSString *)name withAttributes:(TCSymbolAttribute)attributes containedBy:(TCSymbol *)parent;

-(instancetype) initWithName:(NSString*) name withAttributes:(TCSymbolAttribute) attributes;
-(instancetype) initWithName:(NSString*) name withAttributes:(TCSymbolAttribute) attributes containedBy:(TCSymbol*) parent;


@end
