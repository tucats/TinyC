//
//  TCExpression.m
//  Language
//
//  Created by Tom Cole on 4/2/14.
//
//

#import "TCExpression.h"

#import "TCToken.h"
#import "TCParser.h"
#import "TCExpressionInterpreter.h"
#import "TCExpressionParser.h"


@implementation TCExpression

+(TCValue*) evaluateString:(NSString *)string
{
    return [TCExpression evaluateString:string withDebugging:NO error:nil];

}

+(TCValue*) evaluateString:(NSString *)string withDebugging:(BOOL) debug error:(TCError**)error
{
    TCParser * parser = [[TCParser alloc] initFromDefaultFile:@"LanguageTokens.plist"];
    
        // Lex the command, and dump it as a diagnostic step.
    [parser lex:string];
    if( debug ) {
        [parser dump];
    }
    
    // Given a lexed string, parse an expression
    TCExpressionParser * exp = [[TCExpressionParser alloc]init];
    TCSyntaxNode * tree = [exp parse:parser];
    
    if( debug ) {
        [tree dumpTree];
    }
    if(exp.error) {
        NSLog(@"%@", exp.error);
        return nil;
    }
    
    // Now evaluate it.
    TCExpressionInterpreter * intepreter = [[TCExpressionInterpreter alloc]init];

    TCValue * result = [intepreter evaluate:tree withSymbols:nil];
    if(intepreter.error && (error != nil)) {
        *error = intepreter.error;
        return nil;
    }
    return result;
}


+(TCValue*) evaluateString:(NSString *)string withDebugging:(BOOL) debug
{
    return [TCExpression evaluateString:string withDebugging:debug error:nil];
}


@end
