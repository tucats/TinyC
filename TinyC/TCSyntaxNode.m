//
//  SyntaxNode.m
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import "TCSyntaxNode.h"

NSString * nodeSpelling( int nodeType ) {
    
    switch(nodeType) {
        case LANGUAGE_REFERENCE:
            return @"REFERENCE";
        case LANGUAGE_RELATION:
            return @"RELATION";
        case LANGUAGE_SCALAR:
            return @"SCALAR";
        case LANGUAGE_EXPRESSION:
            return @"EXPRESSION";
        case LANGUAGE_MONADIC:
            return @"MONADIC";
        case LANGUAGE_DIADIC:
            return @"DIADIC";
        case LANGUAGE_DECLARE:
            return @"DECLARE";
        case LANGUAGE_NAME:
            return @"NAME";
        case LANGUAGE_BLOCK:
            return @"BLOCK";
        case LANGUAGE_ASSIGNMENT:
            return @"ASSIGNMENT";
        case LANGUAGE_ADDRESS:
            return @"ADDRESS";
        case LANGUAGE_IF:
            return @"IF";
        case LANGUAGE_RETURN:
            return @"RETURN";
        case LANGUAGE_REFERENCE_ARG:
            return @"REFERENCE ARG";
        case LANGUAGE_CALL:
            return @"CALL";
        case LANGUAGE_RETURN_TYPE:
            return @"RETURN TYPE";
        case LANGUAGE_MODULE:
            return @"MODULE";
        case LANGUAGE_ENTRYPOINT:
            return @"ENTRYPOINT";
        case LANGUAGE_TYPE:
            return @"TYPE";
        case LANGUAGE_CAST:
            return @"CAST";
        case LANGUAGE_ARRAY:
            return @"ARRAY";
        case LANGUAGE_DEREFERENCE:
            return @"DEREFERENCE";
        case LANGUAGE_FOR:
            return @"FOR";
            
        default:
            return [[NSString alloc]initWithFormat:@"%d", nodeType];
    }
}


@implementation TCSyntaxNode

/**
 Class helper method to create a new instance of the given node type.
 @param type the SyntaxNodeType to use, such as LANGUAGE_BLOCK or LANGUAGE_RETURN
 @returns the newly created instance.
 */

+(instancetype)node:(SyntaxNodeType) type
{
    return [[TCSyntaxNode alloc]initWithType:type];
    
}

-(instancetype)init
{
    NSLog(@"FATAL - called wrong initializer!");
    return nil;
}

/**
 Initializer method to create a new instance of the given node type. This is the
 designated initializer.
 
 @param type the SyntaxNodeType to use, such as LANGUAGE_BLOCK or LANGUAGE_RETURN
 @returns the newly created instance.
 */

-(instancetype)initWithType:(SyntaxNodeType)type
{
    if( self = [super init]) {
        _nodeType = type;
    }
    return self;
}


-(NSString*) description
{
    NSString *d = [NSString stringWithFormat:@"Node %@ %@ %@ %@", nodeSpelling(self.nodeType),
        self.action ? [NSNumber numberWithInt:self.action] : @"",
        self.argument ? [NSString stringWithFormat:@" = %@", self.argument] : @"",
        self.spelling ? [[NSString alloc]initWithFormat:@"\"%@\"", self.spelling]: @""
        ];
    return d;

}


// Dump the current node at the given level.  Dump any children
// and the next level in.
-(void) dumpLevel:(int) level
{
    NSString * indent = [@"-------------------" substringToIndex:(level*2)];
    //NSString * spaces = [@"                   " substringToIndex:(level*2)];
    
    NSLog(@"%@ Node %@ %@ %@ %@", indent, nodeSpelling(self.nodeType),
          self.action ? [NSNumber numberWithInt:self.action] : @"",
          self.argument ? [NSString stringWithFormat:@"= %@", self.argument] : @"",
          self.spelling ? [[NSString alloc]initWithFormat:@"\"%@\"", self.spelling]: @""
          );

    if( self.subNodes) {
        for( TCSyntaxNode * t in self.subNodes)
            [t dumpLevel:(level+1)];
    }
}

-(void) dumpTree
{
    [self dumpLevel:0];
    
}
-(void) addNode:(TCSyntaxNode *)newNode
{
    if( _subNodes == nil) {
        _subNodes = [NSMutableArray array];
    }
    [self.subNodes addObject:newNode];
}

-(int) nodeAction
{
    return _action;
}
@end
