//
//  TCValue.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>


typedef enum {
    TCVALUE_UNDEFINED=0,
    TCVALUE_CHAR,
    TCVALUE_BOOLEAN,
    TCVALUE_INT,
    TCVALUE_LONG,
    TCVALUE_FLOAT,
    TCVALUE_DOUBLE,
    TCVALUE_STRING,
    TCVALUE_USER,
    TCVALUE_POINTER = 16384,
    TCVALUE_POINTER_CHAR = TCVALUE_POINTER + TCVALUE_CHAR,
    TCVALUE_POINTER_INT = TCVALUE_POINTER + TCVALUE_INT,
    TCVALUE_POINTER_LONG = TCVALUE_POINTER + TCVALUE_LONG,
    TCVALUE_POINTER_FLOAT = TCVALUE_POINTER + TCVALUE_FLOAT,
    TCVALUE_POINTER_DOUBLE = TCVALUE_POINTER + TCVALUE_DOUBLE
} TCValueType;

@interface TCValue : NSValue


{
    int         intValue;
    long        longValue;
    double      doubleValue;
    NSString *  stringValue;
    TCValueType type;
}

+(int) sizeOf:(TCValueType)type;

-(instancetype)initWithDouble:(double) value;
-(instancetype)initWithString:(NSString*) value;
-(instancetype)initWithInt:(int) value;
-(instancetype)initWithLong:(long) value;
-(instancetype) initWithChar:(char) value;

-(int)compareToValue:(TCValue*) value;
-(TCValue*) castTo:(TCValueType)newType;
-(TCValue*) addValue:(TCValue*) value;
-(TCValue*) subtractValue:(TCValue*) value;
-(TCValue*) divideValue:(TCValue*) value;
-(TCValue*) moduloValue:(TCValue*) value;
-(TCValue*) multiplyValue:(TCValue*) value;

-(TCValue *) makePointer:(TCValueType)ofType;

-(TCValue*) negate;
-(TCValue*) booleanNot;

-(TCValueType)getType;
-(NSString*) getTypeName;

-(long)getLong;
-(int)getInt;
-(double)getDouble;
-(NSString*) getString;
-(char) getChar;

//-(TCValue*) getValue:(long)address ofType:(TCValueType) type;

@end
