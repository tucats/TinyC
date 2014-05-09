//
//  TCDeclarationParser.h
//  Language
//
//  Created by Tom Cole on 4/5/14.
//
//

#import <Foundation/Foundation.h>
#import "TCLexicalScanner.h"
#import "TCSyntaxNode.h"


@interface TCDeclarationParser : NSObject

{
    BOOL _endOnComma;
}

@property BOOL debug;

-(TCSyntaxNode * ) parse: (TCLexicalScanner*) scanner;
-(TCSyntaxNode*) parseSingle:(TCLexicalScanner *)scanner;


@end
