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
        BOOL sigAbort = NO;
        
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
                            
                        case 'm':
                            df |= TCDebugMemory;
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
            if( strcmp(argv[ax], "-a") == 0) {
                sigAbort = YES;
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
                //printf("Creating runtime memory area of %ld bytes\n", memory);
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
                printf("Usage:   tinyc  [-d[tpxs]] [-a] [-m n] file\n");
                printf("    -dt   Dump token queue\n");
                printf("    -dp   Dump parse tree\n");
                printf("    -dx   Trace execution\n");
                printf("    -ds   Trace storage\n");
                printf("    -dm   Summarize memory use\n");
                printf("    -a    assert() abort\n");
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
        
        // End of options processing, let's do the work.
        //
        // 1. Allocate a TinyC instance to handle the work, and initialize it's storage and options.
        
        TCError * error = nil;
        TinyC * tinyC = [[TinyC alloc]init];
        [tinyC setDebug: df];
        tinyC.memorySize = memory;
        tinyC.sigAbort = sigAbort;
        
        // 2. If we have a file, compile that, else compile the string we captured.
        
        if( path == nil )
            error = [tinyC compileString:program];
        else
            error = [tinyC compileFile:path];
        
        if( error != nil ) {
            printf("%s\n", [[error description] UTF8String]);
            return 1;
        }
        
        // 3. Run the program, and capture the return code.  If there was a runtime
        //    error, then report it.
        
        error = [tinyC execute];
        
        if( error != nil ) {
            printf("%s\n", [[error description] UTF8String]);
            return 2;
        }
        
        // 4. Get the program result (it's actual C-language return) and print
        //    that out as well.  We use the description method so we don't care
        //    if the result is numeric or string or whatever; it will be printed
        //    as a string.
        
        printf("Program returns %s\n", [[tinyC.result description] UTF8String]);
        return 0;
    }
    return 0;
}

