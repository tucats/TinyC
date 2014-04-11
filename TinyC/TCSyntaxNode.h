//
//  SyntaxNode.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    LANGUAGE_ENTRYPOINT,
    LANGUAGE_EXPRESSION,
    LANGUAGE_REFERENCE,
    LANGUAGE_ADD,
    LANGUAGE_SUBTRACT,
    LANGUAGE_MULTIPLY,
    LANGUAGE_DIVIDE,
    LANGUAGE_INTEGER_CONSTANT,
    LANGUAGE_DOUBLE_CONSTANT,
    LANGUAGE_STRING_CONSTANT,
    LANGUAGE_RELATION,
    LANGUAGE_DIADIC,
    LANGUAGE_MONADIC,
    LANGUAGE_SCALAR,
    LANGUAGE_DECLARE,
    LANGUAGE_NAME,
    LANGUAGE_BLOCK,
    LANGUAGE_ASSIGNMENT,
    LANGUAGE_ADDRESS,
    LANGUAGE_IF,
    LANGUAGE_RETURN,
    LANGUAGE_RETURN_TYPE,
    LANGUAGE_REFERENCE_ARG,
    LANGUAGE_CALL,
    LANGUAGE_MODULE
} SyntaxNodeType;

@interface TCSyntaxNode : NSObject

@property SyntaxNodeType nodeType;
@property NSString *spelling;
@property int action;
@property NSObject * argument;
@property NSMutableArray * subNodes;

-(void) addNode: (TCSyntaxNode*) newNode;
-(void) dumpTree;
-(int) nodeAction;


@end
