//
//  TCprintfFunction.m
//  TinyC
//
//  Created by Tom Cole on 4/18/14.
//  Copyright (c) 2014 Forest Edge. All rights reserved.
//

#import "TCprintfFunction.h"
#import "NSString+NSStringFormatting.h"

@implementation TCprintfFunction

-(TCValue*) execute:(NSArray *)arguments
{
    
    // Simplest case, no arguments and we have no work.
    
    if( arguments == nil || arguments.count == 0 ) {
        self.error = nil;
        return [[TCValue alloc]initWithLong:0];
    }
    
    // We will accumulate the arguments into an array of data
    // items loaded from memory or directly referenced by
    // value as appropriate
    
    NSMutableArray * valueArgs = [NSMutableArray array];
    TCValue* formatValue = (TCValue*) arguments[0];
    NSString * formatString = [formatValue getString];
    
    for( int i = 1; i < arguments.count; i++ ) {
        TCValue * x = (TCValue*) arguments[i];
        if( x.getType == TCVALUE_POINTER_CHAR) {
            [valueArgs addObject:[self.storage getString:x.getLong]];
        } else if( x.getType == TCVALUE_STRING)
            [valueArgs addObject:x.getString];
        else if( x.getType == TCVALUE_BOOLEAN)
            [valueArgs addObject:[NSNumber numberWithBool:x.getLong]];
        else if( x.getType == TCVALUE_INT)
            [valueArgs addObject:[NSNumber numberWithInteger:x.getInt]];
        else if( x.getType == TCVALUE_LONG)
            [valueArgs addObject:[NSNumber numberWithLong:x.getLong]];
        else if( x.getType == TCVALUE_DOUBLE)
            [valueArgs addObject:[NSNumber numberWithDouble:x.getDouble]];
        else if( x.getType >= TCVALUE_POINTER)
            [valueArgs addObject:[NSNumber numberWithLong:x.getLong]];
        else {
            NSLog(@"ERROR: unusable argument type %d cannot be added to arglist ", x.getType);
            
        }
    }

    // Call our custom formatting function that uses an array of values.  The resulting
    // buffer is then processed through the escape string manager to convert "\n" to an
    // actual new line, etc.
    
    NSString * buffer = [[NSString stringWithFormat:formatString array:valueArgs] escapeString];
    
    int bytesPrinted = printf("%s", [buffer UTF8String]);
    return [[TCValue alloc]initWithInt: bytesPrinted];
}

@end
