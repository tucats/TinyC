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

NSString * loadProgramFromFile(FILE * input)
{
    NSString *program= nil;
    NSMutableString *argBuff = [NSMutableString string];
    while(!feof(stdin)) {
        char buffer[256];
        char *bp;
        bp = fgets(buffer, 255, input);
        if(!bp)
            break;
        [argBuff appendString:[NSString stringWithCString:bp
                                                 encoding:NSUTF8StringEncoding]];
        [argBuff appendString: @"\n"];
    }
    program = [NSString stringWithString:argBuff];
    return program;
}

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        
        NSString * program = nil;
        NSString * path = nil;
        
        long memory = 65536L;
        
        TCFlag df = TCDebugNone;
        BOOL argCapture = NO;
        NSMutableArray *argList = [NSMutableArray array];
        
        // Scan over the runtime argument list.  Some will be processed
        //  by the main program as runtime options.  Once we find the
        //  program name to run, all remaining arguments are just copied
        //  into the runtime space of the TinyC program being executed.
        for( int ax = 1; ax < argc; ax++ ) {
            
            if(argCapture) {
                [argList addObject:[NSString stringWithUTF8String:argv[ax]]];
                continue;
            }
            
            //  Debug flag begins with -d followed by one or more letters
            //  indicating debug modes.
            if( strncmp(argv[ax], "-d", 2) == 0 ) {
                for( int dp = 2; dp < strlen(argv[ax]); dp++) {
                    char c = (argv[ax])[dp];
                    switch (c) {
                        case 'p':
                            df |= TCDebugParse;     //  -dp     show parse tree
                            break;
                            
                        case 'm':
                            df |= TCDebugMemory;    //  -dm     show runtime memory stats
                            break;
                            
                        case 't':
                            df |= TCDebugTokens;    //  -dt     show token queue
                            break;
                            
                        case 'x':
                            df |= TCDebugTrace;     //  -dx     execution trace
                            break;
                            
                        case 's':
                            df |= TCDebugStorage;   //  -ds     storage trace
                            break;
                            
                        case 'r':
                            df |= TCNonRandomNumbers;// -dr     Deterministic random numbers
                            break;
                            
                        default:
                            printf("Unrecognized -d option %c ignored\n", c);
                            break;
                    }
                }
                continue;
            }
            if( strcmp(argv[ax], "-a") == 0) {
                df |= TCFatalAsserts;
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
                continue;
            }
            if( strcmp(argv[ax], "-") == 0 || strcmp(argv[ax], "-stdin") == 0) {
                program = loadProgramFromFile(stdin);
                argCapture = YES;
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
                printf("    -dr   Do not use true random numbers\n");
                printf("    -a    assert() abort\n");
                printf("    -m n  Allocate n bytes to runtime storage\n");
                return -3;
            }
            path = [NSString stringWithCString:argv[ax] encoding:NSUTF8StringEncoding];
            argCapture = YES;
        }
        
        if( path == nil && program == nil) {
            
            // No input file given on command line, so let's assume we are
            // just reading everything from stdin and hope for the best.
            
            program = loadProgramFromFile(stdin);
            path = nil;
        }
        
        // End of options processing, let's do the work.
        //
        // 1. Allocate a TinyC instance to handle the work, and initialize it's storage and options.
        
        TCError * error = nil;
        TinyC * tinyC = [TinyC allocWithMemory:memory flags:df];
        
        // 2. If we have a file, compile that, else compile the string we captured.
        
        if( path == nil )
            error = [tinyC compileString:program module:@"__COMMAND_LINE__"];
        else
            error = [tinyC compileFile:path];
        
        if( error != nil ) {
            printf("%s\n", [[error description] UTF8String]);
            return -1000;
        }
        
        // 3. Run the program, and capture the return code.  Whatever argument
        //    list was grabbed by the command line, put the module name at
        //    the start of the list (argv[0]).  If there was a runtime
        //    error, then report it.
        
        [argList insertObject:tinyC.moduleName atIndex:0];
        
        error = [tinyC executeWithArguments:argList];
        
        if( error != nil ) {
            printf("%s\n", [[error description] UTF8String]);
            return -1001;
        }
        
        // 4. Get the program result (it's actual C-language return) and print
        //    that out as well.  We use the description method so we don't care
        //    if the result is numeric or string or whatever; it will be printed
        //    as a string.
        
        int rc = tinyC.result.getInt;
        
        if( rc != 0)
            printf("Program returns %s\n", [[tinyC.result description] UTF8String]);
        return rc;
    }
    return 0;
}

