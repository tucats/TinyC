//
//  TCDeclarationParser.h
//  Language
//
//  Created by Tom Cole on 4/5/14.
//
//

#import <Foundation/Foundation.h>
#import "TCSymtanticParser.h"
#import "TCSyntaxNode.h"


@interface TCDeclarationParser : NSObject


@property BOOL debug;

-(TCSyntaxNode * ) parse: (TCSymtanticParser*) parser;


@end
