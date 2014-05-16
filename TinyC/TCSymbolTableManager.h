//
//  TCSymbolTableManager.h
//  TinyC
//
//  Created by Tom Cole on 5/16/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TCSymbolTable.h"
#import "TCSyntaxNode.h"
#import "TCError.h"

@interface TCSymbolTableManager : NSObject

@property TCSymbolTable * tableRoot;
@property TCSymbolTable * activeTable;

@property TCError* error;

-(BOOL) allocateStorageForTree:(TCSyntaxNode*) tree;

@end
