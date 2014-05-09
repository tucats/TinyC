//
//  Parser.h
//  Language
//
//  Created by Tom Cole on 11/19/08.
//  Copyright 2008 SAS Institute Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCToken.h"
#import "TCError.h"

#define DEFAULT_FILE_NAME @"LanguageTokens.plist"
#define VERSION_KEY       @"__version__"

@interface TCLexicalScanner : NSObject {
	
    NSString *persistantFileName;
	NSString *buffer;
	TCToken *lastToken;
	int	tokenKind;
	NSArray *lineMap;
	NSMutableArray *tokenList;
	long tokenPosition;
	long charPos;
	NSScanner * scanner;
	NSMutableDictionary *_dictionary;
    NSMutableDictionary *_spellingTable;
}

@property (readonly) int dictionaryVersion;

@property (readonly) BOOL dictionaryChanged;
@property (readonly) BOOL wasDictionaryLoaded;

@property TCError* error;


/**
 Initialize using a file in the user's default (home) directory.
 */
-(instancetype) initFromDefaultFile: (NSString *) fileName;
-(instancetype) initFromFile: (NSString *) fileName;

/**
 Mark the token dictionary so that it is NOT rewritten to disk if
 it has been modified by this program. This is typically used when a dictionary
 is created by the running program and not used externally.
 */
-(void) doNotPersist;


-(void) addSpelling:(NSString*)theSpelling forToken:(TokenType) code;

-(TokenType) nextToken;
-(long) lex:(NSString*) string;
-(long) count;
-(long) position;
-(void) setPosition:(long) newPosition;
-(BOOL) lexNext;
-(void) dump;
-(NSString*) getLineAtLine:(long)lineNumber;
-(NSString*) getLineAtPosition:(long) position;
-(NSString*) currentLineText;
-(long) currentLineNumber;

-(long) currentPosition;

-(BOOL) isAtEnd;

-(BOOL) isNextToken:(TokenType) ofType;
-(BOOL) isNextToken:(NSString*) spelling ofType:(TokenType) tokenType;
-(BOOL) isNextIdentifier:(NSString*) spelling;
-(BOOL) isNextSpecial:(NSString*) spelling;

-(TokenType) lastTokenType;
-(long) tokenPosition;

/**
 Get the spelling of the last token that was processed by the nextToken method.
 */
-(NSString*) lastSpelling;

/**
 Signal an error at the current position of the parse
 @param code the TCErrorType code to report
 */
-(void) error:(TCErrorType) code;

@end
