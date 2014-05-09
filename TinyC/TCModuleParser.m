//
//  TCModuleParser.m
//  Language
//
//  Created by Tom Cole on 4/9/14.
//
//

#import "TCModuleParser.h"
#import "TCStatementParser.h"
#import "TCTypeParser.h"
#import "TCDeclarationParser.h"

@implementation TCModuleParser
-(TCSyntaxNode*) parse:(TCLexicalScanner *)scanner
{
    return [self parse:scanner name:@"__ANONYMOUS__"];
}


-(TCSyntaxNode*) parse:(TCLexicalScanner *)scanner name:(NSString*) name
{
    
    TCSyntaxNode * module = [TCSyntaxNode node:LANGUAGE_MODULE usingScanner:scanner];
    module.subNodes = [NSMutableArray array];
    module.spelling = name;
    module.position = scanner.tokenPosition;
    
    while( 1 ) {
        if([scanner isAtEnd])
            break;
        
        // Each entry point starts with a type def
        
        TCTypeParser * typeDecl = [[TCTypeParser alloc]init];
        TCSyntaxNode * decl = [typeDecl parse:scanner];
        

        if( decl == nil ) {
            scanner.error = [[TCError alloc]initWithCode:TCERROR_EXP_FUNC usingScanner:scanner];
            return nil;
        }

        // Parse the entry point name
        if( ![scanner isNextToken:TOKEN_IDENTIFIER]) {
            scanner.error = [[TCError alloc]initWithCode:TCERROR_EXP_ENTRYPOINT usingScanner:scanner];
            return nil;
        }
        decl.spelling = scanner.lastSpelling;
        
        // Parse the block.
        
        if( decl.subNodes.count <= 1 && [scanner isNextToken:TOKEN_PAREN_LEFT]) {
            
            TCSyntaxNode * varData = [TCSyntaxNode node:LANGUAGE_RETURN_TYPE usingScanner:scanner];
            varData.position = scanner.tokenPosition;
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
                if([scanner isNextToken:TOKEN_PAREN_RIGHT]) {
                    break;
                }
                if( requireComma && ![scanner isNextToken:TOKEN_COMMA]) {
                    scanner.error = [[TCError alloc]initWithCode:TCERROR_EXP_COMMA usingScanner:scanner];
                    return nil;
                }

                TCSyntaxNode * arg = [dp parseSingle:scanner];
                if( scanner.error) {
                    return nil;
                }
                if( arg == nil || arg.nodeType != LANGUAGE_DECLARE){
                    scanner.error = [[TCError alloc]initWithCode:TCERROR_EXP_DECLARATION usingScanner:scanner];
                    return nil;
                }
                [decl.subNodes addObject:arg];
                
                // Later, handle var-args here
                
                requireComma = YES;
            }
            
            // Now, need body of function
            
            TCStatementParser * block = [[TCStatementParser alloc]init];
            
            TCSyntaxNode * blockTree = [block parse:scanner];
            if( !blockTree || scanner.error) {
                return nil;
            }
            
            [decl.subNodes addObject:blockTree];
            
        }

        [module.subNodes addObject:decl];
    }
    
    return module;
}
@end
