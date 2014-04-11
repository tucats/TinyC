//
//  TCError.m
//  Language
//
//  Created by Tom Cole on 4/6/14.
//
//

#import "TCError.h"

@implementation TCError

#pragma mark - Class methods

+(NSString*) errorTextForCode:(TCErrorType)code
{
    
    // For now this is a simple hard-coded map.  Later, we'll load
    //  from a localizable resource.
    
    switch(code) {
            
        case TCERROR_NONE:
            return @"success";
            
        case TCERROR_ERROR:
            return @"general error";
            
        case TCERROR_FATAL:
            return @"fatal internal error, %@";
            
        case TCERROR_IDENTIFIERNF:
            return @"expected identifier not found";
        case TCERROR_OPERANDNF:
            return @"expected operand not found";
        case TCERROR_SEMICOLON:
            return @"expected ';' not found";
        case TCERROR_PARENMISMATCH:
            return @"mismatched parenthesis";
        case TCERROR_INTERP_BAD_SCALAR:
            return @"Unrecognized SCALAR type %@";
        case TCERROR_INTERP_UNIMP_MODADIC:
            return @"Unimplemented monadic operator %@";
        case TCERROR_INTERP_UNIMP_DIADIC:
            return @"Unimplemented diadic operator %@";
        case TCERROR_INTERP_UNIMP_RELATION:
            return @"Unimplemented relation operator %@";
        case TCERROR_INTERP_UNIMP_NODE:
            return @"Unimplemented node type %@";
        case TCERROR_UNK_STATEMENT:
            return @"Unknown statement %@";
        case TCERROR_UNK_IDENTIFIER:
            return @"Unknown identifier %@";
        case TCERROR_EXP_COMMA:
            return @"Expected comma not found";
        case TCERROR_EXP_ENTRYPOINT:
            return @"Expected entry point definition not found";
        case TCERROR_UNK_ENTRYPOINT:
            return @"Call to unknown entrypoint %@";
        case TCERROR_ARG_MISMATCH:
            return @"Argument mismatch";
        case TCERROR_EXP_DECLARATION:
            return @"Expected declaration not found";
        case TCERROR_EXP_ARGUMENT:
            return @"Expected function argument not found";
        case TCERROR_UNINIT_VALUE:
            return @"Illegal read from uninitialized value";
        case TCERROR_BREAK:
            return @"!BREAK";
        case TCERROR_RETURN:
            return @"!RETURN";
        case TCERROR_SIGNAL:
            return @"!SIGNAL";
            
        default:
            return [NSString stringWithFormat:@"<error %d>", code];
    }
}

#pragma mark - Initialization methods

/**
 This is the designated initializer
 
 Create a new TCError instance prepopulated with the error info
 @param code the TCErrorType code for the error
 @param source the source buffer where the offending error was encountered, if any
 @param position the position in the source buffer where the error was found
 @returns a new instance of the object
 */
-(instancetype) initWithCode:(TCErrorType)code inSource:(NSString *)source atPosition:(long)position
{
    if(( self = [super init])) {
        _code = code;
        _sourceText = source;
        _position = position;
    }
    return self;
}

-(instancetype) initWithCode:(TCErrorType)code withArgument:(NSObject *)argument
{
    if((self = [super init])){
        _code = code;
        _argument = argument;
        _sourceText = nil;
        _position = 0;
    }
    return self;
}


#pragma mark - Query methods

-(BOOL) isError
{
    return ((_code > 0));
}

-(BOOL) isBreak
{
    return ((_code == TCERROR_BREAK));
}


-(BOOL) isReturn
{
    return ((_code == TCERROR_RETURN));
}


-(BOOL) isSignal
{
    return ((_code == TCERROR_SIGNAL));
}


-(NSString *) errorMessage
{
    NSString *msgString =[NSString stringWithFormat:@"Error, %@",[TCError errorTextForCode:_code ]];

    // Simple case, no argument so just form the message text.
    if( _argument == nil) {
        return msgString;
    }
    
    // Slightly harder case, there is an argument so the error text is actually itself
    // a format string.
    
    
    return [NSString stringWithFormat:msgString, _argument];
    
}
-(NSString*) description
{
 
    NSMutableString * message = nil;
    
    if( _argument != nil ) {
        message = [NSMutableString stringWithString:[self errorMessage]];
    }
    else {
        message = [NSMutableString stringWithFormat:[self errorMessage], _argument];
    }
    
    
    if( _sourceText != nil) {
        [message appendString:@"\n"];
        
        // Starting at the error position, search backwards to see if there is
        // a line break - we only want to print the source line with the error
        // and not the whole buffer if it is a multi-line buffer.
        
        long positionOffset = 0;
        NSRange line;
        line.location = 0;
        line.length = [_sourceText length];
        
        for( long dx = _position; dx>0; dx--) {
            if( [_sourceText characterAtIndex:dx] == '\n') {
                positionOffset = _position - dx;
                line.location = dx;
                line.length = line.length - dx;
                break;
            }
        }
        
        // Now that we have an offset, search from there to the end of
        // the string to see if there is a second delimiter we should care
        // about.
        
        for( long dx = (long) line.location; dx < [_sourceText length]; dx++) {
            if([_sourceText characterAtIndex:dx] == '\n') {
                line.length = dx;
                break;
            }
        }
        
        [message appendString:[_sourceText substringWithRange:line]];
        
        // If the position is in the string (rather than the start)
        // the point to the right place in the string.
        if( _position > 0 ) {
            [message appendString:@"\n"];
            for( int i = 0; i < (_position-positionOffset); i++ )
                [message appendString:@"-"];
            [message appendString:@"^"];
        }
    }
    return [message copy];
    
}
@end
