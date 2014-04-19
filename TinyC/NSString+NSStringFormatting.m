//
//  NSString+NSStringFormatting.m
//  TinyC
//
//  Created by Tom Cole on 4/11/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "NSString+NSStringFormatting.h"
#import "TCValue.h"

@implementation NSString (NSStringFormatting)


/**
 Given an array of TCValue objects, format each one for output.
 
 @param format the NSString containing the standard C formatting string data
 @param arguments an NSArray containing NSNumber or NSString values for formatting
 @returns a new string created using the format string and arguments
 */

+ (id)stringWithFormat:(NSString *)format array:(NSArray*) arguments
{
    NSMutableString * buffer = [NSMutableString string];

    int ix;
    int argp = 0;
    for( ix = 0; ix < format.length; ix++ ) {
        
        char ch = [format characterAtIndex:ix];
        if( ch != '%') {
            [buffer appendFormat:@"%c", ch];
            continue;
        }
        
        // It's a format operator, capture the format
        // string contents.
        
        int start = ix;
        int length = 1;
        for( ix = ix + 1 ; ix < format.length; ix++ ){
            ch = [format characterAtIndex:ix];
            length++;
            if(ch == 'd' ||
               ch == 'p' ||
               ch == 's' ||
               ch == 'x' ||
               ch == 'X' ||
               ch == 'f' ||
               ch == '@')
                break;
        }
        NSNumber * v = arguments[argp++];
        NSString *f = [format substringWithRange:NSMakeRange(start, length)];
        
        //NSLog(@"DEBUG: Format value is %@, data is %@", f, v);
        
        switch (ch) {
            case 'd':
            case 'x':
            case 'X':
            case 'p':

                [buffer appendString:[NSString stringWithFormat:f, v.integerValue]];
                break;

            case 'f':
                [buffer appendString:[NSString stringWithFormat:f, v.doubleValue]];
                break;

                case 's':
                [buffer appendString:[NSString stringWithFormat:f, [(NSString*)v cStringUsingEncoding:NSUTF8StringEncoding]]];
                break;
                
            default:
                NSLog(@"FATAL: unusable format spec %@", [format substringWithRange:NSMakeRange(start, length)]);
                break;
        }
        
    }
    return [NSString stringWithString:buffer];
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
