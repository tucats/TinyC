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

-(TCSymbol*) newSymbol:(NSString *)name ofType:(TCValueType)type storage:(TCStorage*) storage
{
    
    TCSymbol *symbol = [[TCSymbol alloc]init];
    symbol.spelling = name;
    symbol.type = type;
    switch( type) {
        case TCVALUE_INT:
            symbol.size = sizeof(int);
            break;
        case TCVALUE_CHAR:
            symbol.size = sizeof(char);
            break;
        case TCVALUE_DOUBLE:
            symbol.size = sizeof(double);
            break;
        case TCVALUE_FLOAT:
            symbol.size = sizeof(float);
            break;
        case TCVALUE_LONG:
            symbol.size = sizeof(long);
            break;
        case TCVALUE_POINTER:
            symbol.size = sizeof(char*);
            break;
        default:
            symbol.size = sizeof(long);
    }
    symbol.address = [storage allocateAuto:symbol.size];
    symbol.allocated = YES;
    [_symbols setObject:symbol forKey:name];
    return symbol;
}


@end
