//
//  Token.h
//  Language
//
//  Created by Tom Cole on 11/19/08.
//  Copyright 2008 SAS Institute Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef  enum TOKEN_TYPE {
	TOKEN_INTEGER = 128,  // This ensures that token types and value types never collide.
	TOKEN_DOUBLE,
    TOKEN_FLOAT,
	TOKEN_STRING, 
	TOKEN_IDENTIFIER, 
	TOKEN_SPECIAL, 
	TOKEN_EOS,
	TOKEN_PRINT,
	TOKEN_ASSIGNMENT,
	TOKEN_END,
	TOKEN_ADD,
	TOKEN_SUBTRACT,
	TOKEN_DIVIDE,
	TOKEN_ASTERISK,
	TOKEN_NOT,
	TOKEN_MINUS,
    TOKEN_EQUAL,
    TOKEN_NOT_EQUAL,
    TOKEN_GREATER_OR_EQUAL,
    TOKEN_GREATER,
    TOKEN_LESS_OR_EQUAL,
    TOKEN_LESS,
    TOKEN_PAREN_LEFT,
    TOKEN_PAREN_RIGHT,
    TOKEN_BRACKET_LEFT,
    TOKEN_BRACKET_RIGHT,
    TOKEN_BRACE_LEFT,
    TOKEN_BRACE_RIGHT,
    TOKEN_BOOLEAN_AND,
    TOKEN_BOOLEAN_OR,
    TOKEN_DECL_INT,
    TOKEN_DECL_DOUBLE,
    TOKEN_DECL_CHAR,
    TOKEN_DECL_FLOAT,
    TOKEN_DECL_POINTER,
    TOKEN_DECL_LONG,
    TOKEN_COMMA,
    TOKEN_SEMICOLON,
    TOKEN_IF,
    TOKEN_ELSE,
    TOKEN_RETURN,
    TOKEN_FOR,
    TOKEN_WHILE,
    TOKEN_AMPER,
    TOKEN_BREAK,
    TOKEN_CONTINUE,
    TOKEN__MAXVALUE
} TokenType;

@interface TCToken : NSObject

@property int type;
@property long position;
@property NSString * spelling;
-(id) initWithSpelling:(NSString *) tokenSpelling ofType:(TokenType) tokenKind atPosition:(long) tokenPosition;
@end
