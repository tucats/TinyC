//
//  TCModuleParser.m
//  Language
//
//  Created by Tom Cole on 4/9/14.
//
//

#import "TCModuleParser.h"
#import "TCStatement.h"

@implementation TCModuleParser
-(TCSyntaxNode*) parse:(TCParser *)parser
{
    return [self parse:parser name:@"__ANONYMOUS__"];
}


-(TCSyntaxNode*) parse:(TCParser *)parser name:(NSString*) name
{
    TCError * error = nil;
    
    TCSyntaxNode * module = [[TCSyntaxNode alloc]init];
    module.nodeType = LANGUAGE_MODULE;
    module.subNodes = [NSMutableArray array];
    module.spelling = name;
    TCStatement * statementParser = [[TCStatement alloc]init];
    
    while( 1 ) {
        if([parser isAtEnd])
            break;
        
        TCSyntaxNode * entryPoint = [statementParser parse:parser error:&error options:TCSTATEMENT_SUBSTATEMENT];
        if( entryPoint == nil )
            return nil;
        if( entryPoint.nodeType != LANGUAGE_ENTRYPOINT) {
            parser.error = [[TCError alloc]initWithCode:TCERROR_EXP_ENTRYPOINT withArgument:nil];
            return nil;
        }
        [module.subNodes addObject:entryPoint];
    }
    
    return module;
}
@end
