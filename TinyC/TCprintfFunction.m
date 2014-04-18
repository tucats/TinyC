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
    NSMutableArray * valueArgs = [NSMutableArray array];
    TCValue* formatValue = (TCValue*) arguments[0];
    NSString * formatString = [formatValue getString];
    
    for( int i = 1; i < arguments.count; i++ ) {
        TCValue * x = (TCValue*) arguments[i];
        if( x.getType == TCVALUE_CHAR + TCVALUE_POINTER) {
            [valueArgs addObject:[self.storage getString:x.getLong]];
        } else if( x.getType == TCVALUE_STRING)
            [valueArgs addObject:x.getString];
        else if( x.getType == TCVALUE_BOOLEAN)
            [valueArgs addObject:[NSNumber numberWithBool:x.getLong]];
        else if( x.getType == TCVALUE_INT)
            [valueArgs addObject:[NSNumber numberWithLong:x.getLong]];
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
    NSString * buffer = [[NSString stringWithFormat:formatString array:valueArgs] escapeString];
    //NSString *newString = [buffer stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    
    int bytesPrinted = printf("%s", [buffer UTF8String]);
    return [[TCValue alloc]initWithInt: bytesPrinted];
}

@end
