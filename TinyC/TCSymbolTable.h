//
//  TCSymbolTable.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>
#import "TCSymbol.h"
#import "TCSyntaxNode.h"
#import "TCValue.h"
#import "TCStorage.h"

@interface TCSymbolTable : NSObject

@property NSMutableDictionary* symbols;
@property TCSymbolTable * parent;


//-(TCSymbol*) newSymbol: (NSString*) name ofType:(TCSymbolType)type;
-(TCSymbol*) findSymbol: (NSString*) name;
-(TCValue * ) valueOfSymbol: (NSString*) name;
-(TCSymbol*) newSymbol:(NSString *)name ofType:(TCValueType)type storage:(TCStorage*) storage;

@end
