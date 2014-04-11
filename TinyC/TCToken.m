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
 */

-(id) initWithSpelling:(NSString *) tokenSpelling ofType:(TokenType) tokenKind atPosition:(int) tokenPosition {
    
    if(self = [super init]) {
        _spelling = [[NSString alloc] initWithString:tokenSpelling];
        type = tokenKind;
        position = tokenPosition;
    }
    return self;
    
    
}

-(id) init {
	return [self initWithSpelling:@"" ofType:0 atPosition:0];
}


-(NSString*) description {
    
    static char * typeNames[] = {
        "INTEGER", "DOUBLE", "STRING", "IDENTIFIER", "SPECIAL", "EOS"
    };
    
    if( type <= TOKEN_EOS )
        return [[NSString alloc] initWithFormat:@"%-8s \"%@\"", typeNames[type], _spelling];
    else
        return [[NSString alloc] initWithFormat:@"TOK(%3d) \"%@\"", type, _spelling];
    
    
}
@end
