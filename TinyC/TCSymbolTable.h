//
//  TCSymbolTable.h
//  TinyC
//
//  Created by Tom Cole on 5/15/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCSymbol.h"

@interface TCSymbolTable : NSObject

/** The parent/container symbol table for this table. @note This will be nil for
    the top-level symbol table of a compilation unit, but all other subordinate
    tables will point to the container table. */
@property   TCSymbolTable *         parent;

/** The base address of allocations in this symbol table.  This will be 0L for
 the top-most table that contains static/global declarations.  For subordinate
 tables it will contain the base address allocated at runtime. */
@property   long                    baseAddress;

/** This counts the depth of the table; the top-level module table is depth=0
    and each subordinate table below has an increased depth. */
@property   int                     depth;

/** This is the set of symbols defined in this particular table. */
@property   NSMutableDictionary*    symbols;

/**
 Helper function to initialize an instance of the table,
 and identify the container symbol table.
 @param parent the container symbol table, or nil if this is the
 global symbol table for the compilation unit.
 @return an initialized symbol table.
 */
-(instancetype) initWithParent:(TCSymbolTable*) parent;

/**
 Add a new symbol to the local symbol table scope. 
 @param symbol a symbol object that is to be added to the local table.
 @return true if the symbol was succesfully added, or false if the
 symbol was not be added because it was a duplicate
 of a symbol already in the table.
 */
-(BOOL) addSymbol:(TCSymbol*) symbol;

/**
 Fetch the symbol information for a given name. This searches the
 current table, and then progresses to each successive parent table
 to locate the symbol. 
 
 @param name the name of the symbol to locate
 @returns the symbol found, or nil if it was not found in any active
 symbol table.
 */
-(TCSymbol*) findSymbol:(NSString*) name;


@end
