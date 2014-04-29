//
//  ExpressionParser.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>
#import "TCSymtanticParser.h"
#import "TCSyntaxNode.h"

@interface TCExpressionParser : NSObject

@property BOOL debug;
@property TCError *error;

-(TCSyntaxNode * ) parse: (TCSymtanticParser*) parser;

@end
