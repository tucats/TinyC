//
//  TCSymbol.h
//  TinyC
//
//  Created by Tom Cole on 5/15/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A symbol in the compile-time symbol table.
 
 A symbol contains information about a symbol.  This always includes
 it's name and data type.  It may also include informationa about the
 storage of the symbol's data, or a container (such as a struct or
 union) for the symbol.
 
 This information is used to store type and eventually allocation
 informaiton during the compilation phase for TinyC.
 */
@class TCSymbolTable;

typedef enum  {
    /** Symbol is of undefined or unsupported type */
    TC_SYMBOL_UNDEFINED =   0,
    
    //  Base types.  These all fit within an 8-bit byte
    /** Symbol is a scalar char */
    TC_SYMBOL_CHAR =        1,
    /** Symbol is a scalar int */
    TC_SYMBOL_INT =         2,
    /** Symbol is a scalar long */
    TC_SYMBOL_LONG =        3,
    /** Symbol is a scalar float */
    TC_SYMBOL_FLOAT =       4,
    /** Symbol is a scalar double float */
    TC_SYMBOL_DOUBLE =      5,
    /** Symbol is a user-provided typedef */
    TC_SYMBOL_TYPEDEF =     6,

    //  Modifiers. Must all be bits above the base byte.
    /** Symbol is a structure */
    TC_SYMBOL_STRUCT =      (1<<8),
    /** Symbol is a pointer to the base type */
    TC_SYMBOL_POINTER =     (1<<9),
    /** Symbol is an array of the base type */
    TC_SYMBOL_ARRAY =       (1<<10),
    /** Symbol is stored as an offset from a base pointer */
    TC_SYMBOL_OFFSET =      (1<<11),
    /** Symbol is stored an absolute address */
    TC_SYMBOL_STATIC =      (1<<12),
    /** Symbol is stored as an offset from the frame pointer */
    TC_SYMBOL_AUTO =        (1<<13),
    /** Symbol is an enumeration */
    TC_SYMBOL_ENUM =        (1<<14)
} TCSymbolAttribute;

/**
 Given a TCSymbolAttribute value, extract the base type
 */
#define BASETYPE(t)  (t & 0x0FF)

/**
 Given a TCSymbolAttribute value, extract the modifier bits.
 */
#define MODIFIERS(t) (t & 0xFFFFFF00L)

@interface TCSymbol : NSObject

/** The name of the symbol */
@property   NSString *          name;

/** The base type and modifier bits for the data type */
@property   TCSymbolAttribute   attributes;

/** The symbol table that contains this symbol */
@property   TCSymbolTable *     table;

/** The assigned absolute address or relative offset */
@property   long                address;

/** The size of the data type for scalars, or the number of
    bytes of storage used by the struct or array */
@property   int                 size;

/** The parent container if this is a member of a struct or
    union, or nil for all other symbol types. */
@property   TCSymbol *          parent;         // This is the container symbol (struct, etc.) if appropriate

/**
 Class helper to allocate and create a new symbol.
 
 @param name the name of the symbol
 @param attributes the base type and modifier attribute bits
 @param parent the container symbol for struct or unions, or nil for other symbols.
 @return a new instance of a symbol.
 */
+(instancetype) symbolWithName:(NSString *)name
                withAttributes:(TCSymbolAttribute)attributes
                   containedBy:(TCSymbol *)parent;

/**
 Helper to initialize a new symbol.
 
 @param name the name of the symbol
 @param attributes the base type and modifier attribute bits
 @return a new instance of a symbol.
 */
-(instancetype) initWithName:(NSString*)name
              withAttributes:(TCSymbolAttribute) attributes;

/**
 Helper to initialize a new symbol.
 
 @param name the name of the symbol
 @param attributes the base type and modifier attribute bits
 @param parent the container symbol for struct or unions, or nil for other symbols.
 @return a new instance of a symbol.
 */
-(instancetype) initWithName:(NSString*) name
              withAttributes:(TCSymbolAttribute) attributes
                 containedBy:(TCSymbol*) parent;


@end
