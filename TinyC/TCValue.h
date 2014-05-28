//
//  TCValue.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//  Define a runtime data value for the C language.  This can be a
//  scalar data type, or a pointer to a scalar data type.  In the
//  future, user types such as struct can be added.

#import <Foundation/Foundation.h>

/**
 This enumeration defines the data types. Each possible scalar type is
 listed, with zero being reserved as an undefined value.  Pointer data 
 types are the same as the scalar equivalient with the TC_VALUE_POINTER
 added, which sets bit 16 in the value.
 */
typedef enum {
    /** An undefined data item. This should never exist at runtime */
    TCVALUE_UNDEFINED=0,
    
    /** A char, 16-bit integer that holds a character */
    TCVALUE_CHAR,
    
    /** A boolean, 16-bit integer that holds a boolean (0/1) value */
    TCVALUE_BOOLEAN,
    
    /** An int 32-bit integer value */
    TCVALUE_INT,
    
    /** A long 64-bit integer value */
    TCVALUE_LONG,
    
    /** A float 32-bit floating point value */
    TCVALUE_FLOAT,
    
    /** A double 64-bit floating point value */
    TCVALUE_DOUBLE,
    
    /** A compiler-generated value containing an NSString */
    TCVALUE_STRING,
    
    /** A user-defined value (not currently supported) */
    TCVALUE_USER,
    
    /** An un-typed pointer; also used as the flag value 
        to indicate a pointer to an existing scalar type */
    TCVALUE_POINTER = 16384,
    
    /** A pointer to a "char" data item */
    TCVALUE_POINTER_CHAR = TCVALUE_POINTER + TCVALUE_CHAR,
    
    /** A pointer to an "int" data item */
    TCVALUE_POINTER_INT = TCVALUE_POINTER + TCVALUE_INT,
    
    /** A pointer to a "long" data item */
    TCVALUE_POINTER_LONG = TCVALUE_POINTER + TCVALUE_LONG,
    
    /** A pointer to a "float" data item */
    TCVALUE_POINTER_FLOAT = TCVALUE_POINTER + TCVALUE_FLOAT,
    
    /** A pointer to a "double" data item */
    TCVALUE_POINTER_DOUBLE = TCVALUE_POINTER + TCVALUE_DOUBLE
} TCValueType;

@interface TCValue : NSValue


{
    /** The scalar value when it is a char, boolean, or int value */
    int         intValue;
    
    /** The scalar value when it is a long value */
    long        longValue;
    
    /** The scalar value when it is a float or double value */
    double      doubleValue;
    
    /** The value when it is a compiler-generated string constant */
    NSString *  stringValue;
    
    /** The type of this value */
    TCValueType type;
}


#pragma mark - Initializers

/** 
 A class helper function to calculate the size of the storage area 
 for a value of the given type.
 
    @param type the TCValueType to compute the sizeof() value.
    @return the number of bytes of storage this item would consume.
 */
+(int) sizeOf:(TCValueType)type;

/**
 Create a new instance of a TCValue of type double with the supplied
 initial value.
 
    @param value the double to store in the runtime value
    @return the initialized instance of the value
 */
-(instancetype)initWithDouble:(double) value;

/**
 Create a new instance of a TCValue of type string with the supplied
 initial value.
 
    @param the string to store in the runtime value
    @return the initialized instance of the value
 */
-(instancetype)initWithString:(NSString*) value;

/**
 Create a new instance of a TCValue of type int with the supplied
 initial value.
 
    @param value the int to store in the runtime value
    @return the initialized instance of the value
 */
-(instancetype)initWithInt:(int) value;

/**
 Create a new instance of a TCValue of type long with the supplied
 initial value.
 
    @param value the long to store in the runtime value
    @return the initialized instance of the value
 */
-(instancetype)initWithLong:(long) value;

/**
 Create a new instance of a TCValue of type char with the supplied
 initial value.
 
    @param value the char to store in the runtime value
    @return the initialized instance of the value
 */
-(instancetype) initWithChar:(char) value;

#pragma mark - Comparison and casting

/**
 Compare the current value to another value, and return -1, 0, or 1 
 to indicate the result of the comparison.
 
 The comparison takes care of type promotion so that comparisons
 are done using the type of greatest precision or domain.
 
    @param value the TCValue to compare to the current value
    @return an integer indicating the relation between the current and passed value.
 
 The possible values are -1 indicating current value is less than the value being 
 compared with, 0 indicating the current value is equal to the value being compared 
 with, or 1 indicating the current value is greater than the value being compared 
 with.
 */
-(int)compareToValue:(TCValue*) value;

/**
 Convert the current value to a different type and return a TCValue of that type.
 The returned value may or may not be the same as the current object depending on
 the nature of the conversion.  If the new type and existing type are the same
 then the current object is returned.
 
    @param newType the type to convert the current value to.
    @return a TCValue of the given type
 */
-(TCValue*) castTo:(TCValueType)newType;

/**
 Cast the current item to a pointer of the given type.  The actual value
 is not modified, and must be an integer or long value as it holds the
 runtime memory address of data.  
 
 @param the type of pointer this value holds
 @return a TCValue of the appropriate type.  This may or may not be the
 same value as the method is passed to.
 */
-(TCValue *) makePointer:(TCValueType)ofType;


#pragma mark - Basic math
/**
 Add a value to the current value, and return a new value with the sum
 of the values.
 
 The data types will be promoted appropriately so the addition operation
 happens using the type with largest domain or precision of the two
 types.  That is, an int and a long are added as two longs as the result
 is a long.
 
    @param value the value to add to the current value.
    @return the sum of the items
 */
-(TCValue*) addValue:(TCValue*) value;

/**
 Subtract a value from the current value, and return a new value with the
 difference of the values.
 
 The data types will be promoted appropriately so the addition operation
 happens using the type with largest domain or precision of the two
 types.  That is, an int and a long are subtracted as two longs and the 
 result is a long.
 
    @param value the value to subtract from the current value.
    @return the difference of the items
 */
-(TCValue*) subtractValue:(TCValue*) value;


/**
 Divide a value into the current value, and return a new value with the
 dividend.
 
 The data types will be promoted appropriately so the addition operation
 happens using the type with largest domain or precision of the two
 types.  That is, an int and a long are divided as two longs and the
 result is a long.
 
    @param value the value to divide into the current value.
    @return the dividend of the items
 */
-(TCValue*) divideValue:(TCValue*) value;


/**
 Divide a value into the current value, and
 return a new value with the integer remainder.
 
 The data types will be promoted appropriately so the addition operation
 happens using the type with largest domain or precision of the two
 types.  That is, an int and a long are divided as two longs and the
 result is a long.
 
    @param value the value to divide into the current value.
    @return the remainder of the division of the items
 */
-(TCValue*) moduloValue:(TCValue*) value;


/**
 Multiply a value with the current value, and return a new value with the
 product of the values.
 
 The data types will be promoted appropriately so the addition operation
 happens using the type with largest domain or precision of the two
 types.  That is, an int and a long are multiplied as two longs and the
 result is a long.
 
    @param value the value to multiply with the current value.
    @return the product of the items
 */
-(TCValue*) multiplyValue:(TCValue*) value;


-(TCValue*) negate;
-(TCValue*) booleanNot;

#pragma mark - Descriptions

/**
 Get the type of the current value (int, long, double, etc.)
 
    @return a TCValueType describing this item's data type.  
 
 The returned type may be a scalar value with TCVALUE_POINTER 
 added to indicate a pointer-to value.
 */
-(TCValueType)getType;

/**
 Get the C name for the current value's type.
 
    @return an NSString containing the name, such as "double" or "int *"
 */
-(NSString*) getTypeName;

#pragma mark - Data accessor functions

/**
 Get the long value stored in this type.  
 
    @return The value, cast to a long
 */
-(long)getLong;


/**
 Get the int value stored in this type.
 
    @return The value, cast to a int
 */
-(int)getInt;


/**
 Get the double value stored in this type.
 
    @return The value, cast to a double
 */
-(double)getDouble;


/**
 Get the string value of the item stored in this type.
 
    @return The value, formatted as a string
 */

-(NSString*) getString;


/**
 Get the char value stored in this type.
 
    @return The value, cast to a char
 */
-(char) getChar;


@end
