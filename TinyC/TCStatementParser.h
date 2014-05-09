//
//  TCStatement.h
//  Language
//
//  Created by Tom Cole on 4/7/14.
//
//

#import <Foundation/Foundation.h>
#import "TCSyntaxNode.h"
#import "TCLexicalScanner.h"

typedef enum {
    TCSTATEMENT_NONE = 0,
    TCSTATEMENT_SUBSTATEMENT = 1
} TCStatementOptions;

@interface TCStatementParser : NSObject

-(TCSyntaxNode*) parse:(TCLexicalScanner*)scanner  options:(TCStatementOptions)options;
-(TCSyntaxNode*) parse:(TCLexicalScanner*)scanner ;

@end
