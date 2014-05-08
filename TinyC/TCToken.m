//
//  Token.m
//  Language
//
//  Created by Tom Cole on 11/19/08.
//  Copyright 2008 SAS Institute Inc. All rights reserved.
//

#import "TCToken.h"


@implementation TCToken

@synthesize type;
@synthesize position;

/**
 This is the primary init method for this class
 
 @param tokenSpelling the string value of the token
 @param tokenKind the numerical value for the token, normally from the enumeration TokenType
 @param tokenPosition the location in the input buffer where this token is found.  This is
 normally zero for a token in the dictionary; it contains the position when this object is 
 placed in a lexical list.
 @return the newly-initialized token object.
 */

-(id) initWithSpelling:(NSString *) tokenSpelling ofType:(TokenType) tokenKind atPosition:(long) tokenPosition {
    
    if(self = [super init]) {
        _spelling = [[NSString alloc] initWithString:tokenSpelling];
        type = tokenKind;
        position = tokenPosition;
    }
    return self;
    
    
}

/** This method just calls the primary method initWithSpelling:ofType:atPosition: 
 and passes en an empty string and zeroes for the type and position.
 */
-(id) init {
	return [self initWithSpelling:@"" ofType:0 atPosition:0];
}

/**
 Return a description of this token by showing the spelling and type
 */
-(NSString*) description {
    
    static char * typeNames[] = {
        "INTEGER", "DOUBLE", "FLOAT", "STRING", "IDENTIFIER", "SPECIAL", "CHAR", "EOS"
    };
    
    if( type <= TOKEN_EOS )
        return [[NSString alloc] initWithFormat:@"%-8s \"%@\"", typeNames[type-128], _spelling];
    else
        return [[NSString alloc] initWithFormat:@"TOK(%3d) \"%@\"", type, _spelling];
    
    
}
@end
