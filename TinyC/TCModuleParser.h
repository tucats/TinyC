//
//  TCModuleParser.h
//  Language
//
//  Created by Tom Cole on 4/9/14.
//
//

#import <Foundation/Foundation.h>
#import "TCSymtanticParser.h"
#import "TCSyntaxNode.h"

@interface TCModuleParser : NSObject

-(TCSyntaxNode*) parse:(TCSymtanticParser*) parser;
-(TCSyntaxNode*) parse:(TCSymtanticParser *)parser name:(NSString*) name;
@end
