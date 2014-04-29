//
//  TCIfParser.h
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//

#import <Foundation/Foundation.h>

#import "TCSyntaxNode.h"
#import "TCSymtanticParser.h"
#import "TCError.h"

@interface TCIfParser : NSObject
-(TCSyntaxNode * ) parse: (TCSymtanticParser*) parser;

@end
