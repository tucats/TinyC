//
//  TCSymbolTableManager.m
//  TinyC
//
//  Created by Tom Cole on 5/16/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCSymbolTableManager.h"

@implementation TCSymbolTableManager

-(BOOL) allocateStorageForSubTree:(TCSyntaxNode*) tree
{

    TCSymbolTable * savedTable = _activeTable;
    
    BOOL didAllocate = NO;
    
    // First, see if this is a declaration node, in which
    // case we have work to do.
    
    if(tree.nodeType == LANGUAGE_DECLARE) {
        
        // Process each of the subnodes which declares a specific scalar or
        // (eventually) user-defined type such as a struct, etc.
        
        
        return YES;
    }
    
    // If this is a block, then we need to create a new syntax node for the block.
    else if(tree.nodeType == LANGUAGE_BLOCK) {
        
        TCSymbolTable * newTable = [[TCSymbolTable alloc] initWithParent:_activeTable];
        _activeTable = newTable;
        
    }
    
    // Scan over any children of this node.
    for( int ix = 0; ix < tree.subNodes.count; ix++ ) {
        didAllocate |= [self allocateStorageForSubTree:tree.subNodes[ix]];
    }
    
    // After all that, make sure that the symbol table tree is trimmed
    // of anything we added from this node down. Then return the flag
    // showing if we added anything.
    
    _activeTable = savedTable;
    return didAllocate;
}


-(BOOL) allocateStorageForTree:(TCSyntaxNode *)tree
{
    _tableRoot = [[TCSymbolTable alloc] initWithParent:nil];
    _activeTable = _tableRoot;
    
    _error = nil;
    return [self allocateStorageForSubTree: tree];
}
@end
