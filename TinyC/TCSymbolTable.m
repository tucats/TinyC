//
//  TCSymbolTable.m
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import "TCSymbolTable.h"
#import "TCToken.h"

@implementation TCSymbolTable

-(instancetype) init
{
    if(self = [super init]) {
        _symbols = [NSMutableDictionary dictionary];
    }
    return self;
    
}

-(TCValue *) valueOfSymbol:(NSString *)name
{
    return [[self findSymbol:name] initialValue];
    
}

-(TCSymbol *) findSymbol:(NSString*) name
{
    
    TCSymbol * symbol = [_symbols objectForKey:name];
    if( symbol == nil && _parent != nil )
        symbol = [_parent findSymbol:name];
    return symbol;
}

-(TCSymbol*) newSymbol:(NSString *)name ofType:(TCValueType)type storage:(TCStorageManager*) storage
{
    
    TCSymbol *symbol = [[TCSymbol alloc]init];
    symbol.spelling = name;
    symbol.type = type;
    symbol.size = [TCValue sizeOf:type];
    long storageSize = 0;
    
    if( type > TCVALUE_POINTER )
        storageSize = sizeof(char*);
    else
        storageSize = symbol.size;
    
    symbol.address = [storage allocateAuto:storageSize];
    symbol.allocated = YES;
    [_symbols setObject:symbol forKey:name];
    return symbol;
}


@end
