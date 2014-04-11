//
//  TinyC.m
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//

#import "TinyC.h"
#import "TCValue.h"
#import "TCParser.h"
#import "TCContext.h"
#import "TCModuleParser.h"


@implementation TinyC

-(TCError*) compileFile:(NSString *)path
{
    NSError * error;

    NSString * source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if( error != nil) {
        //printf("File error %s\n", [[error localizedDescription] UTF8String]);
        return [[TCError alloc]initWithCode:TCERROR_FATAL withArgument:[error localizedDescription]];
    }
    
    _moduleName = [[path lastPathComponent] stringByDeletingPathExtension];
    return [self compileString:source];
}

-(TCError*) compileString:(NSString *)source
{
    
    parser = [[TCParser alloc]init];
    [parser lex:source];
    if( _debug)
        [parser dump];
    _moduleName = @"__STRING__";
    return parser.error;
}

-(TCError*) executeReturningValue:(TCValue *__autoreleasing *)result
{
    TCError * error = [self execute];
    if( result != nil )
        *result = functionResult;
    
    return error;
    
}


-(TCError* ) execute
{
    TCError * error;
    TCModuleParser* module = [[TCModuleParser alloc]init];
    TCSyntaxNode * tree = [module parse:parser name:_moduleName];
    error = parser.error;
    
    functionResult = nil;
    if( error != nil) {
        return error;
    }
    else {
        if( _debug ) {
            [tree dumpTree];
        }
        TCContext * execution = [[TCContext alloc]init];
        execution.debug = _debug;
        
        functionResult = [execution execute:tree
                                 entryPoint:@"main"
                              withArguments:@[ [[TCValue alloc]initWithInteger:10] ]];
        return [execution error];
    }

}
@end
