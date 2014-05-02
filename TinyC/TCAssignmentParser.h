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

/**
 Parse an assignment statement from the input stream
 and return a tree describing the assignment operation
 if one is found.
 
 @param parser the parser that feeds lexical tokens to us
 @return a syntax tree describing the assignment operation,
  or nil if no assignment statement can be parsed
 */
-(TCSyntaxNode * ) parse: (TCSymtanticParser*) parser;


@end
