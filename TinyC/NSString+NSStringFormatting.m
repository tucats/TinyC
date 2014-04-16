//
//  NSString+NSStringFormatting.m
//  TinyC
//
//  Created by Tom Cole on 4/11/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "NSString+NSStringFormatting.h"

@implementation NSString (NSStringFormatting)



+ (id)stringWithFormat:(NSString *)format array:(NSArray*) arguments
{
    
#if 0  // Old version
    NSRange range = NSMakeRange(0, [arguments count]);
    NSMutableData* data = [NSMutableData dataWithLength:sizeof(id) * [arguments count]];
    [arguments getObjects:(__unsafe_unretained id *)data.mutableBytes range:range];
    NSString* result = [[NSString alloc] initWithFormat:format, data.mutableBytes];
    return result;
#endif // Old version
    
    __unsafe_unretained id  * argList = (__unsafe_unretained id  *) calloc(1UL, sizeof(id) * arguments.count);
    for (NSInteger i = 0; i < arguments.count; i++) {
        argList[i] = arguments[i];
    }
    
    NSString* result = [[NSString alloc] initWithFormat:format, *argList] ;//  arguments:(void *) argList];
    free (argList);
    return result;
}

/**
 Reformat the string contents to remove "escaped" characters common to the C programming
 language.
 
 @returns a new string with the escapes converted.
 
 */
- (NSString*) escapeString
{
    NSString * escapedString = self;
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\\n"      // Newline
                                                             withString:@"\n"];
    
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\\t"      // Tab
                                                             withString:@"\t"];
    
    escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\\\""     // Double quote
                                                             withString:@"\""];
    return escapedString;
}


@end
