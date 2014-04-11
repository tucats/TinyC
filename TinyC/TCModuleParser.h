//
//  TCModuleParser.h
//  Language
//
//  Created by Tom Cole on 4/9/14.
//
//

#import <Foundation/Foundation.h>
#import "TCParser.h"
#import "TCSyntaxNode.h"

@interface TCModuleParser : NSObject

-(TCSyntaxNode*) parse:(TCParser*) parser;
-(TCSyntaxNode*) parse:(TCParser *)parser name:(NSString*) name;
@end
