//
//  TCExpression.h
//  Language
//
//  Created by Tom Cole on 4/2/14.
//
//

#import <Foundation/Foundation.h>
#import "TCValue.h"
#import "TCError.h"

@interface TCExpression : NSObject

+(TCValue*) evaluateString:(NSString *)string;
+(TCValue*) evaluateString:(NSString *)string withDebugging:(BOOL) debug;
+(TCValue*) evaluateString:(NSString *)string withDebugging:(BOOL) debug error:(TCError**) error;

@end
