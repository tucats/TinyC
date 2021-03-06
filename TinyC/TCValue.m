//
//  TCValue.m
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import "TCValue.h"

typedef struct {
    char * typeName;
    TCValueType typeCode;
} TypeDict;

@implementation TCValue

#pragma mark - Class helper methods

+(int) sizeOf:(TCValueType)type
{
    TCValueType t = type;
    if(t>TCVALUE_POINTER)
        t=t-TCVALUE_POINTER;
    switch(t) {
        case TCVALUE_CHAR:
            return sizeof(char);
        case TCVALUE_DOUBLE:
            return sizeof(double);
        case TCVALUE_INT:
            return sizeof(int);
        case TCVALUE_FLOAT:
            return sizeof(float);
        case TCVALUE_LONG:
            return sizeof(long);
        case TCVALUE_POINTER:
            return sizeof(char*);
        default:
            return 0;
            
    }
}


#pragma mark - Accessors

-(NSString*) description
{
    return [self getString];
}

-(NSString*) getTypeName
{
    TCValueType t = self.getType;
    int ptrDepth = t / TCVALUE_POINTER;
    TCValueType baseT = t % TCVALUE_POINTER;
    
    
    NSMutableString * s = [NSMutableString string];
    
    switch( baseT) {
        case TCVALUE_CHAR:
            [s appendString:@"char"];
            break;
        case TCVALUE_INT:
            [s appendString:@"int"];
            break;
        case TCVALUE_FLOAT:
            [s appendString:@"float"];
            break;
        case TCVALUE_LONG:
            [s appendString:@"long"];
            break;
        case TCVALUE_DOUBLE:
            [s appendString:@"double"];
            break;
            
        default:
            [s appendString:@"undefined"];
            
    }
    
    for( int idx = 0; idx < ptrDepth; idx++ )
        [s appendString:@"*"];
    return [NSString stringWithString:s];
    
}

-(TCValueType)getType
{
    return type;
}

-(int)getInt
{
    return intValue;
}

-(long)getLong
{
    
    // If we are really a pointer of some kind, return the address value from the long
    if( type > TCVALUE_POINTER) {
        return longValue;
    }
    
    // Otherwise, cast ourselves to the right type.
    
    switch([self getType]) {
            
        case TCVALUE_CHAR:
            return (char) intValue;
            
        case TCVALUE_INT:
            return intValue;
            
        case TCVALUE_LONG:
            return longValue;
            
        case TCVALUE_FLOAT:
        case TCVALUE_DOUBLE:
            return (long) doubleValue;
            
        case TCVALUE_STRING:
            return [stringValue intValue];
            
        default:
            return 0;
    }
}

-(double)getDouble
{
    
    switch([self getType]) {
            
        case TCVALUE_CHAR:
        case TCVALUE_INT:
            return (double)intValue;
            
        case TCVALUE_LONG:
            return (double)longValue;
            
        case TCVALUE_FLOAT:
        case TCVALUE_DOUBLE:
            return doubleValue;
            
        case TCVALUE_STRING:
            return [stringValue doubleValue];
            
        default:
            return 0;
    }
}


-(NSString *)getString
{
    
    TCValueType t = self.getType;
    
    if( t > TCVALUE_POINTER) {
        return [NSString stringWithFormat:@"%@ @ %ld", self.getTypeName, longValue];
    }
    switch(t) {
        case TCVALUE_CHAR:
        case TCVALUE_INT:
            return [NSString stringWithFormat:@"%d", intValue];
            
        case TCVALUE_LONG:
            return [NSString stringWithFormat:@"%ld", longValue];
            
        case TCVALUE_FLOAT:
        case TCVALUE_DOUBLE:
            return [NSString stringWithFormat:@"%f", doubleValue];
            
        case TCVALUE_STRING:
            return stringValue;
            
        default:
            return 0;
    }
}

-(char) getChar
{
    return (char) self.getInt;
}

#pragma mark - Initializers

-(instancetype) initWithString:(NSString *)value;
{
    if((self = [super self])) {
        type = TCVALUE_STRING;
        stringValue = value;
    }
    return self;
}

-(instancetype) initWithLong:(long) value
{
    if((self = [super self])) {
        type = TCVALUE_LONG;
        longValue = value;
    }
    return self;
}

-(instancetype) initWithInt:(int) value
{
    if((self = [super self])) {
        type = TCVALUE_INT;
        intValue = value;
    }
    return self;
}

-(instancetype) initWithChar:(char) value
{
    if((self = [super self])) {
        type = TCVALUE_CHAR;
        intValue = value;
    }
    return self;
}


-(instancetype) initWithDouble:(double) value
{
    if((self = [super self])) {
        type = TCVALUE_DOUBLE;
        doubleValue = value;
    }
    return self;
}

#pragma mark - Conversions

/**
 Whatever type this Value is, mark it as a pointer to that type.
 @returns the value, but with the type extended as a pointer operation.
 */

-(TCValue*) makePointer:(TCValueType) ofType
{
    type = ofType + TCVALUE_POINTER;
    return self;
}


-(TCValue*) castTo:(TCValueType)newType
{
    
    // If we are already the type being cast, no work to do.
    if( [self getType] == newType)
        return self;

    // Type conversions just require changing the stored type value
    if(type > TCVALUE_POINTER && newType > TCVALUE_POINTER) {
        type = newType;
        return self;
    }
    
    // Looks like actual data conversions will be required...
    
    switch (newType) {
            
        case TCVALUE_CHAR:
            
            switch ([self getType]) {
                case TCVALUE_INT: {
                    type = TCVALUE_CHAR;
                    return self;
                }
                case TCVALUE_LONG:
                    return [[TCValue alloc]initWithChar:(char)self.getLong];
                    
                case TCVALUE_DOUBLE:
                    return [[TCValue alloc]initWithChar:(char)doubleValue];
                    
                case TCVALUE_STRING:
                    return [[TCValue alloc]initWithChar:(char)[stringValue intValue]];
                    
                default:
                    NSLog(@"Unsupported conversion of TCValue from %d", newType);
                    return nil;
            }
        case TCVALUE_INT:
            
            switch ([self getType]) {
                case TCVALUE_CHAR:
                case TCVALUE_INT:
                    return [[TCValue alloc]initWithInt:self.getInt];
                    
                case TCVALUE_LONG:
                    return [[TCValue alloc]initWithInt:(int)self.getLong];
                    
                case TCVALUE_DOUBLE:
                    return [[TCValue alloc]initWithInt:doubleValue];
                    
                case TCVALUE_STRING:
                    return [[TCValue alloc]initWithInt:[stringValue intValue]];
                    
                default:
                    NSLog(@"Unsupported conversion of TCValue from %d", newType);
                    return nil;
            }
       case TCVALUE_LONG:
            
            switch ([self getType]) {
                case TCVALUE_CHAR:
                case TCVALUE_INT:
                    return [[TCValue alloc]initWithLong:self.getInt];
                    
                case TCVALUE_LONG:
                    return [[TCValue alloc]initWithLong:self.getLong];

                case TCVALUE_DOUBLE:
                    return [[TCValue alloc]initWithLong:doubleValue];
                    
                case TCVALUE_STRING:
                    return [[TCValue alloc]initWithLong:[stringValue intValue]];
                    
                default:
                    NSLog(@"Unsupported conversion of TCValue from %d", newType);
                    return nil;
            }
            
        case TCVALUE_DOUBLE:
            switch([self getType]) {
                case TCVALUE_CHAR:
                case TCVALUE_INT:
                    return [[TCValue alloc]initWithDouble:(double) intValue];
                case TCVALUE_LONG:
                    return [[TCValue alloc]initWithDouble:(double) longValue];
                case TCVALUE_STRING:
                    return [[TCValue alloc]initWithDouble:[stringValue doubleValue]];
                default:
                    NSLog(@"Unsupported conversion of TCValue from %d", newType);
                    return nil;
                    
            }
            
        case TCVALUE_STRING:
            switch([self getType]) {
                case TCVALUE_CHAR:
                    return [[TCValue alloc]initWithString:[NSString stringWithFormat:@"%c", intValue]];
                case TCVALUE_INT:
                    return [[TCValue alloc]initWithString:[NSString stringWithFormat:@"%d", intValue]];
                case TCVALUE_LONG:
                    return [[TCValue alloc]initWithString:[NSString stringWithFormat:@"%ld", longValue]];
                case TCVALUE_DOUBLE:
                    return [[TCValue alloc]initWithString:[NSString stringWithFormat:@"%f", doubleValue]];
                    
                    
                default:
                    NSLog(@"Unsupported conversion of TCValue to %d", newType);
                    return nil;
                    
            }
        
        case TCVALUE_POINTER_CHAR:
            switch ([self getType]) {

                /* We might be asked to store a string in a pointer */
                case TCVALUE_STRING:
                    
                default:
                    NSLog(@"Unsupported conversion of TCValue to %d", newType);
                    return nil;

            }
        default:
            NSLog(@"Unsupported conversion of TCValue to %d", newType);
            return nil;
    }
}

#pragma mark - Diadic operators

-(TCValue * ) addValue: (TCValue*) value
{
    
    int promotedType = MAX([self getType], [value getType]);
    
    /* Handle special case of pointer math */
    if( promotedType >= TCVALUE_POINTER) {
        TCValueType baseType = promotedType - TCVALUE_POINTER;
        long addr = [self getLong] + [value getLong];
        TCValue * r = [[TCValue alloc]initWithLong:addr];
        return [r makePointer:baseType];
    }

    switch(promotedType) {
            
        case TCVALUE_CHAR:
            return [[TCValue alloc]initWithInt:(char)([self getInt] + [value getInt])];
        case TCVALUE_INT:
            return [[TCValue alloc]initWithInt:([self getInt] + [value getInt])];
        case TCVALUE_LONG:
            return [[TCValue alloc]initWithLong:([self getLong] + [value getLong])];
        case TCVALUE_DOUBLE:
            return [[TCValue alloc]initWithDouble:([self getDouble] + [value getDouble])];
            
        default:
            NSLog(@"Attempt to add unsupported data type %d", promotedType);
            return nil;
    }
}

-(TCValue * ) subtractValue: (TCValue*) value
{
    
    int promotedType = MAX([self getType], [value getType]);
    
    /* Handle special case of pointer math */
    if( promotedType >= TCVALUE_POINTER) {
        TCValueType baseType = promotedType - TCVALUE_POINTER;
        long addr = [self getLong] - [value getLong];
        TCValue * r = [[TCValue alloc]initWithLong:addr];
        return [r makePointer:baseType];
    }

    switch(promotedType) {
        case TCVALUE_CHAR:
            return [[TCValue alloc]initWithInt:(char)([self getInt] - [value getInt])];
        case TCVALUE_INT:
            return [[TCValue alloc]initWithInt:([self getInt] - [value getInt])];
        case TCVALUE_LONG:
            return [[TCValue alloc]initWithLong:([self getLong] - [value getLong])];
        case TCVALUE_DOUBLE:
            return [[TCValue alloc]initWithDouble:([self getDouble] - [value getDouble])];
            
        default:
            NSLog(@"Attempt to add unsupported data type %d", promotedType);
            return nil;
    }
}



-(TCValue * ) multiplyValue: (TCValue*) value
{
    
    int promotedType = MAX([self getType], [value getType]);
    
    /* Handle special case of pointer math */
    if( promotedType >= TCVALUE_POINTER) {
        TCValueType baseType = promotedType - TCVALUE_POINTER;
        long addr = [self getLong] * [value getLong];
        TCValue * r = [[TCValue alloc]initWithLong:addr];
        return [r makePointer:baseType];
    }

    switch(promotedType) {
        case TCVALUE_CHAR:
            return [[TCValue alloc]initWithInt:(char)([self getInt] * [value getInt])];
        case TCVALUE_INT:
            return [[TCValue alloc]initWithInt:([self getInt] * [value getInt])];
        case TCVALUE_LONG:
            return [[TCValue alloc]initWithLong:([self getLong] * [value getLong])];
        case TCVALUE_DOUBLE:
            return [[TCValue alloc]initWithDouble:([self getDouble] * [value getDouble])];
            
        default:
            NSLog(@"Attempt to add unsupported data type %d", promotedType);
            return nil;
    }
}


-(TCValue * ) divideValue: (TCValue*) value
{
    
    int promotedType = MAX([self getType], [value getType]);
    
    /* Handle special case of pointer math */
    if( promotedType >= TCVALUE_POINTER) {
        TCValueType baseType = promotedType - TCVALUE_POINTER;
        long addr = [self getLong] / [value getLong];
        TCValue * r = [[TCValue alloc]initWithLong:addr];
        return [r makePointer:baseType];
    }

    switch(promotedType) {
        case TCVALUE_CHAR:
        {
            char v1 = [self getInt];
            char v2 = [value getInt];
            if( v2 == 0 ) {
                NSLog(@"Divide by zero");
                return 0;
            }
            return [[TCValue alloc]initWithInt:(char)(v1/v2)];
        }
            
        case TCVALUE_INT:
        {
            int v1 = [self getInt];
            int v2 = [value getInt];
            if( v2 == 0 ) {
                NSLog(@"Divide by zero");
                return 0;
            }
            return [[TCValue alloc]initWithInt:(v1/v2)];
        }
        case TCVALUE_LONG:
        {
            long v1 = [self getLong];
            long v2 = [value getLong];
            if( v2 == 0 ) {
                NSLog(@"Divide by zero");
                return 0;
            }
            return [[TCValue alloc]initWithLong:(v1/v2)];
        }
        case TCVALUE_DOUBLE:
            return [[TCValue alloc]initWithDouble:([self getDouble] / [value getDouble])];
            
        default:
            NSLog(@"Attempt to add unsupported data type %d", promotedType);
            return nil;
    }
}


-(TCValue * ) moduloValue: (TCValue*) value
{
    
    int promotedType = MAX([self getType], [value getType]);
    
    switch(promotedType) {
        case TCVALUE_CHAR:
        {
            char v1 = [self getInt];
            char v2 = [value getInt];
            if( v2 == 0 ) {
                NSLog(@"Divide by zero");
                return 0;
            }
            return [[TCValue alloc]initWithInt:(char)(v1 % v2)];
        }
            
        case TCVALUE_INT:
        {
            int v1 = [self getInt];
            int v2 = [value getInt];
            if( v2 == 0 ) {
                NSLog(@"Divide by zero");
                return 0;
            }
            return [[TCValue alloc]initWithInt:(v1 % v2)];
        }
        case TCVALUE_LONG:
        {
            long v1 = [self getLong];
            long v2 = [value getLong];
            if( v2 == 0 ) {
                NSLog(@"Divide by zero");
                return 0;
            }
            return [[TCValue alloc]initWithLong:(v1 % v2)];
        }
        case TCVALUE_DOUBLE:
            return [[TCValue alloc]initWithDouble:(fmod([self getDouble], [value getDouble]))];
            
        default:
            NSLog(@"Attempt to add unsupported data type %d", promotedType);
            return nil;
    }
}




-(int) compareToValue:(TCValue *)value
{
    
    int myType = [self getType];
    int otherType = [value getType];
    
    if( myType != otherType) {
        NSLog(@"Type promotion between %d and %d", myType, otherType);
    }
    
    switch( [self getType]) {
        case TCVALUE_CHAR: {
            char testInt = [self getInt] - [value getInt];
            if( testInt < 0 )
                return -1;
            else if( testInt > 0)
                return 1;
            else return 0;
        }
        case TCVALUE_INT: {
            int testInt = [self getInt] - [value getInt];
            if( testInt < 0 )
                return -1;
            else if( testInt > 0)
                return 1;
            else return 0;
        }
            
        case TCVALUE_LONG: {
            long testLong = [self getLong] - [value getLong];
            if( testLong < 0 )
                return -1;
            else if( testLong > 0)
                return 1;
            else return 0;
        }
            
        case TCVALUE_DOUBLE:
        {
            double d = [self getDouble] - [value getDouble];
            if( d < 0.0) {
                return -1;
            } else {
                return d > 0.0;
            }
        }
            
        default:
            NSLog(@"Attempt to compare unrecognized type %d", [self getType]);
            return 99;
    }
    return 0; // EQUAL
}

#pragma mark - Monadic operators

-(TCValue*) negate
{
    switch( [self getType]) {
        case TCVALUE_CHAR:
            return [[TCValue alloc] initWithInt:(-(char)[self getInt])];
        case TCVALUE_INT:
            return [[TCValue alloc] initWithInt:(-[self getInt])];
        case TCVALUE_LONG:
            return [[TCValue alloc] initWithLong:(-[self getLong])];
            
        case TCVALUE_DOUBLE:
            return [[TCValue alloc] initWithDouble:(-[self getDouble])];
            
        default:
            NSLog(@"Unsupported data type for negation %d", [self getType]);
            return nil;
            
    }
}


-(TCValue*) booleanNot
{
    switch( [self getType]) {
        case TCVALUE_INT:
        case TCVALUE_CHAR:
            return [[TCValue alloc] initWithInt:(![self getInt])];
            
        case TCVALUE_LONG:
            return [[TCValue alloc] initWithInt:(![self getLong])];
            
        case TCVALUE_DOUBLE:
        {
            int result;
            if( [self getDouble] == 0.0)
                result = 1;
            else
                result = 0;
            
            return [[TCValue alloc] initWithInt:result];
        }
        default:
            NSLog(@"Unsupported data type for negation %d", [self getType]);
            return nil;
            
    }
}

@end
