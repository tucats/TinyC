//
//  TCStatement.h
//  Language
//
//  Created by Tom Cole on 4/7/14.
//
//

#import <Foundation/Foundation.h>
#import "TCSyntaxNode.h"
#import "TCParser.h"

typedef enum {
    TCSTATEMENT_NONE = 0,
    TCSTATEMENT_SUBSTATEMENT = 1
} TCStatementOptions;

@interface TCStatement : NSObject

-(TCSyntaxNode*) parse:(TCParser*)parser  options:(TCStatementOptions)options;
-(TCSyntaxNode*) parse:(TCParser*)parser ;

@end
