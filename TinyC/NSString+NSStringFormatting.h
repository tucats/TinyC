//
//  NSString+NSStringFormatting.h
//  TinyC
//
//  Created by Tom Cole on 4/11/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSStringFormatting)

+ (id)stringWithFormat:(NSString *)format array:(NSArray*) arguments;


/**
 Reformat the string contents to remove "escaped" characters common to the C programming
 language.
 
 @returns a new string with the escapes converted.
 
 */

- (NSString*) escapeString;

@end
