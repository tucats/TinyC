//
//  TCAssignmentParser.h
//  Language
//
//  Created by Tom Cole on 4/7/14.
//
//

#import <Foundation/Foundation.h>
#import "TCParser.h"
#import "TCSyntaxNode.h"

@interface TCAssignmentParser : NSObject

@property BOOL debug;

-(TCSyntaxNode * ) parse: (TCParser*) parser;


@end
