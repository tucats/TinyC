//
//  TCError.h
//  Language
//
//  Created by Tom Cole on 4/6/14.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    TCERROR_BREAK=-100,     // Non-error signal values
    TCERROR_RETURN,
    TCERROR_SIGNAL,
    TCERROR_NONE = 0,       // No error
    TCERROR_ERROR = 1,      // Error signal values
    TCERROR_FATAL,
    TCERROR_UNK_STATEMENT,
    TCERROR_IDENTIFIERNF,
    TCERROR_OPERANDNF,
    TCERROR_SEMICOLON,
    TCERROR_PARENMISMATCH,
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
    TCERROR__LASTERROR
} TCErrorType;


@interface TCError : NSObject

@property int code;
@property NSString* message;
@property NSString* sourceText;
@property int position;
@property NSObject *argument;

+(NSString*) errorTextForCode:(TCErrorType) code;
-(NSString*) errorMessage;
-(instancetype) initWithCode:(TCErrorType)code inSource:(NSString*) source atPosition:(int)position;
-(instancetype) initWithCode:(TCErrorType)code withArgument:(NSObject*) argument;
-(BOOL) isError;
-(BOOL) isBreak;
-(BOOL) isReturn;
-(BOOL) isSignal;

@end
