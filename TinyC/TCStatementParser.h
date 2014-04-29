//
//  TCStatement.h
//  Language
//
//  Created by Tom Cole on 4/7/14.
//
//

#import <Foundation/Foundation.h>
#import "TCSyntaxNode.h"
#import "TCSymtanticParser.h"

typedef enum {
    TCSTATEMENT_NONE = 0,
    TCSTATEMENT_SUBSTATEMENT = 1
} TCStatementOptions;

@interface TCStatementParser : NSObject

-(TCSyntaxNode*) parse:(TCSymtanticParser*)parser  options:(TCStatementOptions)options;
-(TCSyntaxNode*) parse:(TCSymtanticParser*)parser ;

@end
