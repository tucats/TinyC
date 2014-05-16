//
//  SyntaxNode.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>
@class TCLexicalScanner;

typedef enum {
    /**
     Function entry point
     
     @note the subNodes contain
     (1) Declaration of the function return type
     (2) Zero or more parameter declarations
     (3)The LANGUAGE_BLOCK body of the function
     */
    LANGUAGE_ENTRYPOINT,
    
    /**
     An expression tree.
     
     @note there can be multiple subnodes.  Each
     subnode is processed as an expression, but only
     the last one is used as the expression result. 
     This supports comma-separated expression lists,
     and is also used internally for auto-increment
     operations within expressions.
     */
    LANGUAGE_EXPRESSION,
    
    /**
     A reference to a named object. This resolves
     to the contents of the named object.
     
     @note the node object pointer is an NSString
     identifying the name of the object.
     */
    LANGUAGE_REFERENCE,
    
    /**
     Add two subnodes together
     @note there must be two subnodes, each of  which
     is treated as a subexpressions whose results are
     added together to create a new result.
     */
    LANGUAGE_ADD,
 
    /**
     Subtrace one subnodes from another
     @note there must be two subnodes, each of  which
     is treated as a subexpressions whose results are
     used as subtrahends (node 1 is subtracted from node 0).
     */
    LANGUAGE_SUBTRACT,

    /**
     Multiply two subnodes together
     @note there must be two subnodes, each of  which
     is treated as a subexpressions whose results are
     multiplied together to create a new result.
     */
    LANGUAGE_MULTIPLY,
    
    /**
     Divide one subnode into another.
     @note there must be two subnodes, each of  which
     is treated as a subexpressions whose results are
     used as divisor and dividend (node 1 is divided
     into node 0) create a new result.
     */
    LANGUAGE_DIVIDE,
    
    /**
     Load an integer constant as the subexpression
     result.
     
     @note the object parameter is an NSNumber that
     contains the numeric value of an int data item.
     */
    LANGUAGE_INTEGER_CONSTANT,

    /**
     Load an double-precision floating point
     constant as the subexpression
     result.
     
     @note the object parameter is an NSNumber that
     contains the numeric value of an double data item.
     */
    LANGUAGE_DOUBLE_CONSTANT,
    
    /**
     Load an string constant as the subexpression
     result.
     
     @note the object parameter is an NSString that
     contains the value of an char* constant data item.
     */
    LANGUAGE_STRING_CONSTANT,
    
    /**
     Compare two subnode expressions and return a
     boolean (int) value as the result
     
     @note the relationship is described by the
     action field, and contains TOKEN_EQUAL, TOKEN_LESSTHAN,
     etc.  The result compares subnode 0 in relation to
     subnode 1.
     */
    LANGUAGE_RELATION,
    
    /**
     Perform a mathematical operation on two subexpressions.
     
     @note the action is described by the action field, and is
     the token representing the action.  For example, TOKEN_AND
     or TOKEN_MULTIPLY.  There will always be two subnodes that
     the diadic operation is performed on; the operation is done
     using node 1 upon node 0.  So for example, a divide would
     divide node 1 into node0.
     */
    LANGUAGE_DIADIC,
    
    
    /**
     Perform a mathematical operation on one subexpressions.
     
     @note the action is described by the action field, and is
     the token representing the action.  For example, TOKEN_NOT
     or TOKEN_NEGATE.  There will always be one subnode that
     the monadic operation is performed on.
     */
    LANGUAGE_MONADIC,
    
    /**
     Represent a single (scalar) value.
     
     @note the object is an NSString containing the user
     representation of the value.  The type is not defined
     in this node; it must be determined by parsing the 
     scalar representation.
     */
    LANGUAGE_SCALAR,
    
    /**
     Variable declaration subtree.
     
     @note The action field contains a base type for the list of variables defined.
     The subNodes enumerate each variable to declare, with additional type
     details in the action fields (specifically indicating if an array or
     pointer to the basetype is being declared.
     */
    LANGUAGE_DECLARE,
    
    /**
     Variable declaration name.
     
     @note this is a subnode of a LANGUAGE_DECLARE node.  It contains the
     name of the item being declared. The action field contains the base
     type but may also have the modifier bits added indicating that the data
     type is a pointer or an array.
     */
    LANGUAGE_NAME,
    
    /**
     Start of a language block {...statements...}
     
     @note this causes a new symbol table to be created for the block,
     so declarations that happen in the block are visible only to statements
     within the block or sub-blocks.  Each function contains at least one
     block, but any compound statements using braces will result in 
     sub-blocks.  There is a subnode for each statement in the block;
     these are processed sequentially by the interpereter or compiler.
     */
    LANGUAGE_BLOCK,
    
    /**
     Assign a value to a target.
     
     @note The first subnode is always the target, and must be resolvable
     to an address.  The second subnode is always the source expressions,
     and resolves to any data type.  The node stores the expressions result
     in the target location.
     */
    LANGUAGE_ASSIGNMENT,
    
    /**
     Determine the address of an item.
     
     @note if there are no subnodes, the object is a simple NSString with
     the name of the object. Otherwise, there is a subnode which contains
     an expression used to calculate the address.
     */
    LANGUAGE_ADDRESS,
    
    /**
     Conditional statement expression.
     
     @note There are always two or three subnodes.  The first subnode is
     an expression which is used to determine if the expression is to be
     considered a boolean true or false value.  If the expression is true
     then the second subnode contains a statement (or a block) that is
     to be executed when it's true.  There can be an optional third
     subnode which is the else-clause and is executed when the conditional
     expression is false. If the third node is missing there is no else-clause
     and execution of the node is considered complete.
     */
    LANGUAGE_IF,
    LANGUAGE_TYPE,
    LANGUAGE_RETURN,
    LANGUAGE_RETURN_TYPE,
    LANGUAGE_REFERENCE_ARG,
    LANGUAGE_CALL,
    LANGUAGE_CAST,
    LANGUAGE_ARRAY,
    LANGUAGE_DEREFERENCE,
    LANGUAGE_FOR,
    LANGUAGE_WHILE,
    LANGUAGE_CONTINUE,
    LANGUAGE_BREAK,
    LANGUAGE_MODULE
} SyntaxNodeType;

@interface TCSyntaxNode : NSObject

@property SyntaxNodeType nodeType;
@property NSString *spelling;
@property int action;
@property NSObject * argument;
@property NSMutableArray * subNodes;
@property long position;
@property TCLexicalScanner * scanner;

+(instancetype) node:(SyntaxNodeType)type usingScanner:(TCLexicalScanner*) parser;
-(instancetype) initWithType:(SyntaxNodeType) type usingScanner:(TCLexicalScanner*) parser;

-(void) addNode: (TCSyntaxNode*) newNode;
-(void) dumpTree;
-(int) nodeAction;


@end
