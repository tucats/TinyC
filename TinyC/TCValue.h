//
//  TCValue.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>


typedef enum {
    TCVALUE_UNDEFINED,
    TCVALUE_INTEGER,
    TCVALUE_FLOAT,
    TCVALUE_DOUBLE,
    TCVALUE_STRING,
    TCVALUE_BOOLEAN
} TCValueType;

@interface TCValue : NSValue

{
    long        intValue;
    double      doubleValue;
    NSString *  stringValue;
    int         type;
}
-(instancetype)initWithDouble:(double) value;
-(instancetype)initWithString:(NSString*) value;
-(instancetype)initWithInteger:(long) value;
-(int)compareToValue:(TCValue*) value;
-(TCValue*) castTo:(TCValueType)newType;
-(TCValue*) addValue:(TCValue*) value;
-(TCValue*) subtractValue:(TCValue*) value;
-(TCValue*) divideValue:(TCValue*) value;
-(TCValue*) multiplyValue:(TCValue*) value;

-(TCValue*) negate;
-(TCValue*) booleanNot;

-(int)getType;
-(long)getInteger;
-(double)getDouble;
-(NSString*) getString;
@end
