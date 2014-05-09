//
//  ExpressionParser.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>
#import "TCLexicalScanner.h"
#import "TCSyntaxNode.h"

@interface TCExpressionParser : NSObject

@property BOOL debug;
@property TCError *error;

-(TCSyntaxNode * ) parse: (TCLexicalScanner*) scanner;

@end
