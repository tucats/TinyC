//
//  TCIfParser.h
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//

#import <Foundation/Foundation.h>

#import "TCSyntaxNode.h"
#import "TCLexicalScanner.h"
#import "TCError.h"

@interface TCIfParser : NSObject
-(TCSyntaxNode * ) parse: (TCLexicalScanner*) scanner;

@end
