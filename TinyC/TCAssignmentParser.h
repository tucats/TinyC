//
//  TCAssignmentParser.h
//  Language
//
//  Created by Tom Cole on 4/7/14.
//
//

#import <Foundation/Foundation.h>
#import "TCSymtanticParser.h"
#import "TCSyntaxNode.h"

@interface TCAssignmentParser : NSObject

@property BOOL debug;

-(TCSyntaxNode * ) parse: (TCSymtanticParser*) parser;


@end
