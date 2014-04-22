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
        
        long memory = 65536L;
        
        TCDebugFlag df = TCDebugNone;
        
        for( int ax = 1; ax < argc; ax++ ) {
            if( strncmp(argv[ax], "-d", 2) == 0 ) {
                for( int dp = 2; dp < strlen(argv[ax]); dp++) {
                    char c = (argv[ax])[dp];
                    switch (c) {
                        case 'p':
                            df |= TCDebugParse;
                            break;
                            
                        case 't':
                            df |= TCDebugTokens;
                            break;
                            
                        case 'x':
                            df |= TCDebugTrace;
                            break;
                            
                        case 's':
                            df |= TCDebugStorage;
                            break;
                            
                        default:
                            printf("Unrecognized -d option %c ignored\n", c);
                            break;
                    }
                }
                continue;
            }
            if( strcmp(argv[ax], "-p") == 0) {
                df |= TCDebugParse;
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
            if( strcmp(argv[ax], "-m") == 0 ) {
                
                long mult = 1;
                char v[32];
                strcpy(v, argv[++ax]);
                int pos = (int) strlen(v) - 1;
                if( pos > 0 ) {
                    char l = tolower(v[pos]);
                    if( !isdigit(l)) {
                        switch(l) {
                            case 'k':
                                mult = 1024;
                                break;
                            case 'm':
                                mult = 1024*1024;
                                break;
                            default:
                                printf("Invalid memory size scaling factor '%c'\n", l);
                                return -1;
                        }
                        v[pos] = 0;
                    }
                }
                memory = atol(v) * mult;
                printf("Creating runtime memory area of %ld bytes\n", memory);
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
                printf("Usage:   tinyc  [-d[tpxs]] [-m n] file\n");
                printf("    -dt   Dump token queue\n");
                printf("    -dp   Dump parse tree\n");
                printf("    -dx   Trace execution\n");
                printf("    -ds   Trace storage\n");
                printf("    -m n  Allocate n bytes to runtime storage\n");
                return -3;
            }
            path = [NSString stringWithCString:argv[ax] encoding:NSUTF8StringEncoding];
            //printf("Program source from file %s\n", [path UTF8String]);
            
        }
        
        if( path == nil && program == nil) {
            path = @"/Users/tom/test.c";
            printf("No source given, using test code\n");
            df = TCDebugParse | TCDebugTrace | TCDebugStorage;
        }
        TCError * error = nil;
        TinyC * tinyC = [[TinyC alloc]init];
        [tinyC setDebug: df];
        tinyC.memorySize = memory;
        
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

