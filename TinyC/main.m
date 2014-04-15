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
        
        TCDebugFlag df = TCDebugStorage;
        
        for( int ax = 1; ax < argc; ax++ ) {
            if( strcmp(argv[ax], "-p") == 0) {
                df |= TCDebugParse;
                //printf("Enable debug flag\n");
                continue;
            }
            if( strcmp(argv[ax], "-t") == 0) {
                df |= TCDebugTokens;
                continue;
            }
            if( strcmp(argv[ax], "-x") == 0) {
                df |= TCDebugTrace;
                continue;
            }
            if( strcmp(argv[ax], "-s") == 0) {
                df |= TCDebugStorage;
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
            
            if( *(argv[ax]) == '-') {
                printf("Unrecognized command line option %s\n", argv[ax]);
                printf("Usage:   tinyc  [-t][-p][-x] file\n");
                printf("    -t   Dump token queue\n");
                printf("    -p   Dump parse tree\n");
                printf("    -x   Trace execution\n");
                printf("    -s   Trace storage\n");
                return -3;
            }
            path = [NSString stringWithCString:argv[ax] encoding:NSUTF8StringEncoding];
            //printf("Program source from file %s\n", [path UTF8String]);
            
        }
        
        if( path == nil && program == nil) {
            program = @"\
            int main( ) \
            { \
            int bob;\
            bob = 3;\
            int age = 54;\
            return bob * age;\
            } ";
            
            printf("No source given, using internal test code\n");
            df = TCDebugParse | TCDebugTrace | TCDebugStorage;
        }
        TCError * error = nil;
        TinyC * tinyC = [[TinyC alloc]init];
        [tinyC setDebug: df];
        
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

