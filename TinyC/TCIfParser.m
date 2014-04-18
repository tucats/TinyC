//
//  TCIfParser.m
//  Language
//
//  Created by Tom Cole on 4/8/14.
//
//

#import "TCIfParser.h"
#import "TCExpressionParser.h"
#import "TCStatement.h"

@implementation TCIfParser



-(TCSyntaxNode*) parse:(TCParser *)parser
{
    
    // Is this an IF statement?
    
    long savedPosition = parser.position;
    if([parser isNextToken:TOKEN_IF]) {
        if([parser isNextToken:TOKEN_PAREN_LEFT]) {
            //NSLog(@"PARSE parse if");

            TCSyntaxNode * tree = [TCSyntaxNode node:LANGUAGE_IF];
            
            TCExpressionParser *exp = [[TCExpressionParser alloc]init];
            TCSyntaxNode * expTree = [exp parse:parser];
            if( exp.error != nil )
                return nil;
            tree.subNodes = [[NSMutableArray alloc]init];
            [tree.subNodes addObject:expTree];
            
            if(![parser isNextToken:TOKEN_PAREN_RIGHT]) {
                parser.error = [[TCError alloc]initWithCode:TCERROR_PARENMISMATCH withArgument:nil];
                return nil;
            }
            TCStatement * stmt = [[TCStatement alloc] init];
            TCError * error = nil;
            
            TCSyntaxNode * condStatement = [stmt parse:parser error:&error options:TCSTATEMENT_SUBSTATEMENT];
            if( error != nil ) {
                parser.error = error;
                return nil;
            }
            [tree.subNodes addObject:condStatement];
            if( [parser isNextToken:TOKEN_ELSE]) {
                //NSLog(@"PARSE parse else");

                condStatement = [stmt parse:parser error:&error options:TCSTATEMENT_SUBSTATEMENT];
                if( error != nil ) {
                    parser.error = error;
                    return nil;
                }
                [tree.subNodes addObject:condStatement];
            }
            return tree;

        }
    }
    
    [parser setPosition:savedPosition];
    return nil;
    }

@end
