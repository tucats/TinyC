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

@property   TCSymbolTable *         parent;
@property   long                    baseAddress;
@property   int                     depth;
@property   NSMutableDictionary*    symbols;

-(instancetype) initWithParent:(TCSymbolTable*) parent;

-(BOOL) addSymbol:(TCSymbol*) symbol;
-(TCSymbol*) findSymbol:(NSString*) name;


@end
