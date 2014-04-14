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

#pragma mark - Accessors

-(NSString*) description
{
    return [self getString];
}

-(int)getType
{
    return type;
}

-(int)getInt
{
    int v = (int) self.getLong;
    return v;
}

-(long)getLong
{
    
    switch([self getType]) {
        case TCVALUE_INT:
        case TCVALUE_LONG:
            return intValue;
            
        case TCVALUE_FLOAT:
        case TCVALUE_DOUBLE:
            return (int) doubleValue;
            
        case TCVALUE_STRING:
            return [stringValue intValue];
        default:
            return 0;
    }
}

-(double)getDouble
{
    
    switch([self getType]) {
        case TCVALUE_INT:
            return (double)intValue;
            
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
    
    switch([self getType]) {
        case TCVALUE_INT:
        case TCVALUE_LONG:
            return [NSString stringWithFormat:@"%ld", intValue];
            
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

-(instancetype) initWithInteger:(long) value
{
    if((self = [super self])) {
        type = TCVALUE_LONG;
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

-(TCValue*) castTo:(TCValueType)newType
{
    
    if( [self getType] == newType)
        return self;
    
    switch (newType) {
        case TCVALUE_LONG:
        case TCVALUE_INT:
            
            switch ([self getType]) {
                case TCVALUE_INT:
                    return [[TCValue alloc]initWithInteger:self.getInt];
                    
                case TCVALUE_LONG:
                    return [[TCValue alloc]initWithInteger:self.getLong];

                case TCVALUE_DOUBLE:
                    return [[TCValue alloc]initWithInteger:doubleValue];
                    
                case TCVALUE_STRING:
                    return [[TCValue alloc]initWithInteger:[stringValue intValue]];
                    
                default:
                    NSLog(@"Unsupported conversion of TCValue from %d", newType);
                    return nil;
            }
            
        case TCVALUE_DOUBLE:
            switch([self getType]) {
                case TCVALUE_INT:
                    return [[TCValue alloc]initWithDouble:(double) intValue];
                case TCVALUE_STRING:
                    return [[TCValue alloc]initWithDouble:[stringValue doubleValue]];
                default:
                    NSLog(@"Unsupported conversion of TCValue from %d", newType);
                    return nil;
                    
            }
            
        case TCVALUE_STRING:
            switch([self getType]) {
                case TCVALUE_INT:
                    return [[TCValue alloc]initWithString:[NSString stringWithFormat:@"%ld", intValue]];
                case TCVALUE_DOUBLE:
                    return [[TCValue alloc]initWithString:[NSString stringWithFormat:@"%f", doubleValue]];
                    
                    
                default:
                    NSLog(@"Unsupported conversion of TCValue from %d", newType);
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
    
    switch(promotedType) {
        case TCVALUE_INT:
            return [[TCValue alloc]initWithInteger:([self getLong] + [value getLong])];
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
    
    switch(promotedType) {
        case TCVALUE_INT:
            return [[TCValue alloc]initWithInteger:([self getLong] - [value getLong])];
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
    
    switch(promotedType) {
        case TCVALUE_INT:
            return [[TCValue alloc]initWithInteger:([self getLong] * [value getLong])];
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
    
    switch(promotedType) {
        case TCVALUE_INT:
        {
            long v1 = [self getLong];
            long v2 = [value getLong];
            if( v2 == 0 ) {
                NSLog(@"Divide by zero");
                return 0;
            }
            return [[TCValue alloc]initWithInteger:(v1/v2)];
        }
        case TCVALUE_DOUBLE:
            return [[TCValue alloc]initWithDouble:([self getDouble] / [value getDouble])];
            
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
        case TCVALUE_INT: {
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
        case TCVALUE_INT:
            return [[TCValue alloc] initWithInteger:(-[self getLong])];
            
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
            return [[TCValue alloc] initWithInteger:(![self getLong])];
            
        case TCVALUE_DOUBLE:
        {
            int result;
            if( [self getDouble] == 0.0)
                result = 1;
            else
                result = 0;
            
            return [[TCValue alloc] initWithInteger:result];
        }
        default:
            NSLog(@"Unsupported data type for negation %d", [self getType]);
            return nil;
            
    }
}


@end
