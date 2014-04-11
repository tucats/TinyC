//
//  TCSymbol.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>
#import "TCValue.h"

typedef enum {
    SYMBOL_INTEGER = TCVALUE_INTEGER,
    SYMBOL_STRING = TCVALUE_STRING,
    SYMBOL_FLOAT = TCVALUE_FLOAT,
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
@end
