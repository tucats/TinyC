//
//  TCModuleParser.m
//  Language
//
//  Created by Tom Cole on 4/9/14.
//
//

#import "TCModuleParser.h"
#import "TCStatement.h"
#import "TCTypeParser.h"
#import "TCDeclarationParser.h"

@implementation TCModuleParser
-(TCSyntaxNode*) parse:(TCParser *)parser
{
    return [self parse:parser name:@"__ANONYMOUS__"];
}


-(TCSyntaxNode*) parse:(TCParser *)parser name:(NSString*) name
{
    
    TCSyntaxNode * module = [TCSyntaxNode node:LANGUAGE_MODULE];
    module.subNodes = [NSMutableArray array];
    module.spelling = name;
    module.position = parser.tokenPosition;
    
    while( 1 ) {
        if([parser isAtEnd])
            break;
        
        // Each entry point starts with a type def
        
        TCTypeParser * typeDecl = [[TCTypeParser alloc]init];
        TCSyntaxNode * decl = [typeDecl parse:parser];
        

        if( decl == nil ) {
            parser.error = [[TCError alloc]initWithCode:TCERROR_EXP_FUNC withArgument:nil];
            return nil;
        }

        // Parse the entry point name
        if( ![parser isNextToken:TOKEN_IDENTIFIER]) {
            parser.error = [[TCError alloc]initWithCode:TCERROR_EXP_ENTRYPOINT withArgument:nil];
            return nil;
        }
        decl.spelling = parser.lastSpelling;
        
        // Parse the block.
        
        if( decl.subNodes.count <= 1 && [parser isNextToken:TOKEN_PAREN_LEFT]) {
            
            TCSyntaxNode * varData = [TCSyntaxNode node:LANGUAGE_RETURN_TYPE];
            varData.position = parser.tokenPosition;
            varData.action = decl.action;
            varData.subNodes = decl.subNodes;
            
            decl.subNodes = [NSMutableArray array];
            [decl.subNodes addObject:varData];
            
            decl.nodeType = LANGUAGE_ENTRYPOINT;
            //decl.spelling = varData.spelling;
            
            // There are zero or more arguments which look like type definitions
            
            TCDeclarationParser * dp = [[TCDeclarationParser alloc]init];
            
            BOOL requireComma = NO;
            while(YES) {
                if([parser isNextToken:TOKEN_PAREN_RIGHT]) {
                    break;
                }
                if( requireComma && ![parser isNextToken:TOKEN_COMMA]) {
                    parser.error = [[TCError alloc]initWithCode:TCERROR_EXP_COMMA withArgument:nil];
                    return nil;
                }

                TCSyntaxNode * arg = [dp parse:parser];
                if( parser.error) {
                    return nil;
                }
                if( arg == nil || arg.nodeType != LANGUAGE_DECLARE){
                    parser.error = [[TCError alloc]initWithCode:TCERROR_EXP_DECLARATION withArgument:nil];
                    return nil;
                }
                [decl.subNodes addObject:arg];
                
                // Later, handle var-args here
                
                requireComma = YES;
            }
            
            // Now, need body of function
            
            TCStatement * block = [[TCStatement alloc]init];
            
            TCSyntaxNode * blockTree = [block parse:parser];
            if( !blockTree || parser.error) {
                return nil;
            }
            
            [decl.subNodes addObject:blockTree];
            
        }

        [module.subNodes addObject:decl];
    }
    
    return module;
}
@end
