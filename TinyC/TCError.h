//
//  TCError.h
//  Language
//
//  Created by Tom Cole on 4/6/14.
//
//

#import <Foundation/Foundation.h>
@class TCLexicalScanner;
@class TCSyntaxNode;

typedef enum {
    TCERROR_BREAK=-100,     // Non-error signal values
    TCERROR_RETURN,
    TCERROR_SIGNAL,
    TCERROR_CONTINUE,
    TCERROR_NONE = 0,       // No error
    TCERROR_ERROR = 1,      // Error signal values
    TCERROR_FATAL,
    TCERROR_UNK_STATEMENT,
    TCERROR_IDENTIFIERNF,
    TCERROR_OPERANDNF,
    TCERROR_SEMICOLON,
    TCERROR_PARENMISMATCH,
    TCERROR_BRACKETMISMATCH,
    TCERROR_BRACEMISMATCH,
    TCERROR_INTERP_BAD_SCALAR,
    TCERROR_INTERP_UNIMP_NODE,
    TCERROR_INTERP_UNIMP_MODADIC,
    TCERROR_INTERP_UNIMP_DIADIC,
    TCERROR_INTERP_UNIMP_RELATION,
    TCERROR_UNK_IDENTIFIER,
    TCERROR_EXP_COMMA,
    TCERROR_EXP_ENTRYPOINT,
    TCERROR_UNK_ENTRYPOINT,
    TCERROR_ARG_MISMATCH,
    TCERROR_EXP_DECLARATION,
    TCERROR_EXP_ARGUMENT,
    TCERROR_UNINIT_VALUE,
    TCERROR_EXP_FUNC,
    TCERROR_EXP_EXPRESSION,
    TCERROR_INV_LVALUE,
    TCERROR_VOIDRETURN,
    TCERROR_RETURNVALUE,
    TCERROR__LASTERROR
} TCErrorType;


@interface TCError : NSObject

@property int code;
@property NSString* message;
@property NSString* sourceText;
@property long position;
@property NSObject *argument;
@property long lineNumber;

+(NSString*) errorTextForCode:(TCErrorType) code;
-(NSString*) errorMessage;
-(instancetype) initWithCode:(TCErrorType)code usingScanner:(TCLexicalScanner*)parser;
-(instancetype) initWithCode:(TCErrorType)code usingScanner:(TCLexicalScanner*)parser withArgument:(NSObject*) argument;
-(instancetype) initWithCode:(TCErrorType)code atNode:(TCSyntaxNode*) node;
-(instancetype) initWithCode:(TCErrorType)code atNode:(TCSyntaxNode*) node withArgument:(NSObject*) argument;

-(BOOL) isError;
-(BOOL) isBreak;
-(BOOL) isReturn;
-(BOOL) isSignal;
-(BOOL) isContinue;

@end
