//
//  TCModuleParser.h
//  Language
//
//  Created by Tom Cole on 4/9/14.
//
//

#import <Foundation/Foundation.h>
#import "TCLexicalScanner.h"
#import "TCSyntaxNode.h"

@interface TCModuleParser : NSObject

-(TCSyntaxNode*) parse:(TCLexicalScanner*) scanner;
-(TCSyntaxNode*) parse:(TCLexicalScanner *)scanner name:(NSString*) name;
@end
