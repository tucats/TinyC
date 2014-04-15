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
    TCVALUE_CHAR,
    TCVALUE_BOOLEAN,
    TCVALUE_INT,
    TCVALUE_LONG,
    TCVALUE_FLOAT,
    TCVALUE_DOUBLE,
    TCVALUE_STRING,
    TCVALUE_POINTER = 16384
} TCValueType;

@interface TCValue : NSValue

{
    int         intValue;
    long        longValue;
    double      doubleValue;
    NSString *  stringValue;
    int         type;
}
-(instancetype)initWithDouble:(double) value;
-(instancetype)initWithString:(NSString*) value;
-(instancetype)initWithInt:(int) value;
-(instancetype)initWithLong:(long) value;
-(int)compareToValue:(TCValue*) value;
-(TCValue*) castTo:(TCValueType)newType;
-(TCValue*) addValue:(TCValue*) value;
-(TCValue*) subtractValue:(TCValue*) value;
-(TCValue*) divideValue:(TCValue*) value;
-(TCValue*) multiplyValue:(TCValue*) value;

-(TCValue*) negate;
-(TCValue*) booleanNot;

-(int)getType;
-(long)getLong;
-(int)getInt;
-(double)getDouble;
-(NSString*) getString;
-(char) getChar;
//-(TCValue*) getValue:(long)address ofType:(TCValueType) type;

@end
