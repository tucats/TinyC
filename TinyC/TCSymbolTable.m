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
    
    // First, see if there is already a symbol of this name in the local
    // symbol table. We do not use the findSymbol method because we
    // only want to search the local table in this case.  IF there is
    // already a symbol of this name then it is an error (duplicate
    // symbol definition.
    
    TCSymbol* testSymbol = [self.symbols objectForKey:symbol.name];
    if(testSymbol!=nil)
        return NO;
    
    // Otherwise, add the symbol by name into the lcoation dictionary,
    // and mark the symbol as being contained by this table.
    [self.symbols setObject:symbol forKey:symbol.name];
    symbol.table = self;
    
    return YES;
}

-(TCSymbol*) findSymbol:(NSString *)name
{
    // First, see if it is in our local table.  If so, job well done!
    TCSymbol * result = [self.symbols objectForKey:name];
    if(result != nil)
        return result;
    
    // Secondly, if we have a parent symbol table, as it to search
    // for the symbol.  Recursively this will search up the entire
    // symbol table tree
    
    if(_parent != nil)
        return [_parent findSymbol:name];
    
    // Third, if there is no parent then we are the root table and
    // the symbol is not found, so return nil.
    return nil;
}
@end
