//
//  TCSymbolTable.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>
#import "TCRuntimeSymbol.h"
#import "TCSyntaxNode.h"
#import "TCValue.h"
#import "TCStorageManager.h"

@interface TCRuntimeSymbolTable : NSObject

@property NSMutableDictionary* symbols;
@property TCRuntimeSymbolTable * parent;


//-(TCSymbol*) newSymbol: (NSString*) name ofType:(TCSymbolType)type;
-(TCRuntimeSymbol*) findSymbol: (NSString*) name;
-(TCValue * ) valueOfSymbol: (NSString*) name;
-(TCRuntimeSymbol*) newSymbol:(NSString *)name ofType:(TCValueType)type storage:(TCStorageManager*) storage;

@end
