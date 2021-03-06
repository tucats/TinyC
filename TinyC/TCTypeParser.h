//
//  TCTypeParser.h
//  TinyC
//
//  Created by Tom Cole on 4/16/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCSyntaxNode.h"
#import "TCLexicalScanner.h"

@interface TCTypeParser : NSObject

-(TCSyntaxNode*) parse:(TCLexicalScanner*)scanner;

@end
