//
//  main.m
//  TinyC
//
//  Created by Tom Cole on 4/11/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCError.h"
#import "TCValue.h"
#import "TinyC.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSString * program = nil;
        NSString * path = nil;
        
        BOOL debugFlag = NO;
        for( int ax = 1; ax < argc; ax++ ) {
            if( strcmp(argv[ax], "-d") == 0) {
                debugFlag = YES;
                //printf("Enable debug flag\n");
                continue;
            }
            if( strcmp(argv[ax], "-") == 0) {
                NSMutableString *argBuff = [NSMutableString string];
                for( int bx = ax+1; bx<argc; bx++) {
                    [argBuff appendString:[NSString stringWithCString:argv[bx] encoding:NSUTF8StringEncoding]];
                    [argBuff appendString: @" "];
                }
                program = [NSString stringWithString:argBuff];
                //printf("Program source from command line\n");
                break;
            }
            
            path = [NSString stringWithCString:argv[ax] encoding:NSUTF8StringEncoding];
            //printf("Program source from file %s\n", [path UTF8String]);
            
        }
        
        if( path == nil && program == nil) {
            program = @"int main( int argc ) { int bob; bob = 100; printf(\"Hello\t%@\n\", bob); return bob+argc} int getinfo( int v ) { return v*100;} ";
            printf("No source given\n");
            debugFlag = YES;
        }
        TCError * error = nil;
        TinyC * tinyC = [[TinyC alloc]init];
        [tinyC setDebug: debugFlag];
        
        if( path == nil )
            error = [tinyC compileString:program];
        else
            error = [tinyC compileFile:path];
        
        if( error != nil ) {
            printf("%s\n", [[error description] UTF8String]);
            return 1;
        }
        
        TCValue * result = nil;
        error = [tinyC executeReturningValue:&result];
        
        if( error != nil ) {
            printf("%s\n", [[error description] UTF8String]);
            return 2;
        }
        
        printf("Program returns %s\n", [[result description] UTF8String]);
        return 0;
    }
    return 0;
}

