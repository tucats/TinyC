//
//  TCSymbol.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>
#import "TCValue.h"
#import "TCStorage.h"

typedef enum {
    SYMBOL_INTEGER = TCVALUE_INTEGER,
    SYMBOL_INT = TCVALUE_INTEGER,
    SYMBOL_LONG = TCVALUE_LONG,
    SYMBOL_STRING = TCVALUE_STRING,
    SYMBOL_FLOAT = TCVALUE_FLOAT,
    SYMBOL_DOUBLE = TCVALUE_DOUBLE,
    SYMBOL_CHAR = TCVALUE_CHAR,
    SYMBOL_POINTER = 100,
    SYMBOL_OFFSET
} TCSymbolType;

@interface TCSymbol : NSObject

@property NSString * spelling;
@property TCSymbolType type;
@property int size;
@property BOOL allocated;
@property TCValue * initialValue;
@property int scope;
@property long address;

-(void) setValue:(TCValue*)value storage:(TCStorage*) storage;


@end
