//
//  TCSymbolTable.m
//  TinyC
//
//  Created by Tom Cole on 5/15/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCSymbolTable.h"

@implementation TCSymbolTable

#pragma mark - Initializers

-(instancetype) initWithParent:(TCSymbolTable*)parent
{
    if((self=[super init])) {
        
        _parent = parent;
        _depth = 0;
        if(parent)
            _depth = parent.depth + 1;
        
        _symbols = [NSMutableDictionary dictionary];
        
    }
    return self;
}

-(instancetype) init
{
    return [self initWithParent:nil];
}

#pragma mark - Symbol Management

-(BOOL) addSymbol:(TCSymbol*) symbol
{
    TCSymbol* testSymbol = [self.symbols objectForKey:symbol.name];
    if(testSymbol!=nil)
        return NO;
    
    [self.symbols setObject:symbol forKey:symbol.name];
    symbol.table = self;
    
    return YES;
}

-(TCSymbol*) findSymbol:(NSString *)name
{
    return [self.symbols objectForKey:name];
}
@end
