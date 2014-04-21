//
//  Parser.m
//  Language
//
//  Created by Tom Cole on 11/19/08.
//  Copyright 2008 SAS Institute Inc. All rights reserved.
//

#import "TCParser.h"


@implementation TCParser

#pragma mark - Constructor and Destructor

/**
 This is the designated init routine for this class.
 */
-(instancetype) initFromFile:(NSString*) fileName
{
    if(self = [super init]) {
        _spellingTable = [NSMutableDictionary dictionary];
        if( fileName ) {
            persistantFileName = fileName;
            NSArray *tempDict = [[NSArray alloc] initWithContentsOfFile:fileName ];
            if( tempDict )
                _dictionary = [[NSMutableDictionary alloc] initWithCapacity:[tempDict count]];
            
            for( NSDictionary * t in tempDict) {
                NSString * spelling = [t valueForKey:@"spelling"];
                NSNumber * typeNum =  [t valueForKey:@"type"];
                int type = (int) [typeNum integerValue];
                
                // Special token that holds dictionary version is handled differently.  Otherwise
                // just add the token data to the dictionary normally.
                if( [spelling isEqualToString:VERSION_KEY]) {
                    _dictionaryVersion = type;
                } else {
                    [self addSpelling:spelling forToken:type];
                }
            }
            _wasDictionaryLoaded = YES;
            _dictionaryChanged = NO;
            
            //NSLog(@"%@ loaded from %@", self, fileName);
        }
        if( !_dictionary) {
            _dictionary = [[NSMutableDictionary alloc]initWithCapacity:100];
            //NSLog(@"No persistent dictionary found, initializing empty dictionary");
            _wasDictionaryLoaded = NO;
            _dictionaryChanged = NO;
        }
        
        // Set up token dictionary
        
        [self addSpelling:@">=" forToken:TOKEN_GREATER_OR_EQUAL];
        [self addSpelling:@">" forToken:TOKEN_GREATER];
        [self addSpelling:@"<=" forToken:TOKEN_LESS_OR_EQUAL];
        [self addSpelling:@"<" forToken:TOKEN_LESS];
        [self addSpelling:@"*" forToken:TOKEN_ASTERISK];
        [self addSpelling:@"/" forToken:TOKEN_DIVIDE];
        [self addSpelling:@"+" forToken:TOKEN_ADD];
        [self addSpelling:@"-" forToken:TOKEN_SUBTRACT];
        [self addSpelling:@"(" forToken:TOKEN_PAREN_LEFT];
        [self addSpelling:@")" forToken:TOKEN_PAREN_RIGHT];
        [self addSpelling:@"==" forToken:TOKEN_EQUAL];
        [self addSpelling:@"!=" forToken:TOKEN_NOT_EQUAL];
        [self addSpelling:@"!" forToken:TOKEN_NOT];
        [self addSpelling:@"&&" forToken:TOKEN_BOOLEAN_AND];
        [self addSpelling:@"||" forToken:TOKEN_BOOLEAN_OR];
        [self addSpelling:@","  forToken:TOKEN_COMMA];
        [self addSpelling:@";"  forToken:TOKEN_SEMICOLON];
        [self addSpelling:@"=" forToken:TOKEN_ASSIGNMENT];
        [self addSpelling:@"int" forToken:TOKEN_DECL_INT];
        [self addSpelling:@"char" forToken:TOKEN_DECL_CHAR];
        [self addSpelling:@"double" forToken:TOKEN_DECL_DOUBLE];
        [self addSpelling:@"float" forToken:TOKEN_DECL_FLOAT];
        [self addSpelling:@"if" forToken:TOKEN_IF];
        [self addSpelling:@"else" forToken:TOKEN_ELSE];
        [self addSpelling:@"return" forToken:TOKEN_RETURN];
        [self addSpelling:@"for" forToken:TOKEN_FOR];
        [self addSpelling:@"while" forToken:TOKEN_WHILE];
        [self addSpelling:@"&" forToken:TOKEN_AMPER];
        [self addSpelling:@"[" forToken:TOKEN_BRACKET_LEFT];
        [self addSpelling:@"]" forToken:TOKEN_BRACKET_RIGHT];
        [self addSpelling:@"{" forToken:TOKEN_BRACE_LEFT];
        [self addSpelling:@"}" forToken:TOKEN_BRACE_RIGHT];
        [self addSpelling:@"break" forToken:TOKEN_BREAK];
        [self addSpelling:@"continue" forToken:TOKEN_CONTINUE];
        [self doNotPersist];

    }
    return self;
}

-(instancetype) init
{
    
    // Let's figure out the default file name we should use.
    NSString * path = [[NSString alloc]initWithFormat:@"%@/%@", NSHomeDirectory(), DEFAULT_FILE_NAME];
    
    return [self initFromFile:path];
}


/**
 Initialize using a file in the user's default (home) directory.
 */
-(instancetype) initFromDefaultFile: (NSString *) fileName
{
    NSString * path = [[NSString alloc]initWithFormat:@"%@/%@", NSHomeDirectory(), fileName];
    return [self initFromFile:path];
}

-(void)doNotPersist
{
    _dictionaryChanged = NO;
}

-(void)dealloc
{
    if( persistantFileName && (_dictionaryChanged == YES)) {
        //NSLog(@"Writing persistant token dictionary");
        
        // The persistance would normally be of Tokens, but that's not supported
        // by plists.  So my first pass at this will be to just manually deconstruct
        // the important info in the object into a dictionary, and then create a
        //  dictionary of dictionaries to see if that will persist.
        
        NSMutableArray *tempDict = [NSMutableArray array];
        
        // Because we are re-writing the dictionary, increment the version and
        // create the special reserved token for it.
        
        _dictionaryVersion += 1;
        NSDictionary *tempToken = [[NSMutableDictionary alloc]init];
        [tempToken setValue:VERSION_KEY forKey:@"spelling"];
        [tempToken setValue:[[NSNumber alloc] initWithInteger:_dictionaryVersion] forKey:@"type"];
        [tempDict addObject:tempToken];
        
        // Now enumerate over the rest of the "real" dictionary to add objects for
        // each item.
        
        [_dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            TCToken *  t = obj;
            NSMutableDictionary *tempToken = [NSMutableDictionary dictionary];
            [tempToken setObject:key                                     forKey:@"spelling"];
            [tempToken setObject:[NSNumber numberWithInteger:[t type]]   forKey:@"type"];
            [tempDict addObject:tempToken];
        }];
        
        [tempDict writeToFile:persistantFileName atomically:YES];
        tempDict = nil;
    }
}

#pragma mark - Token dictionary management

//
//	Add a spelling/value key to the token dictionary.
//
-(void) addSpelling:(NSString*)theSpelling forToken:(TokenType) code {
    
    [_dictionary setObject:[[TCToken alloc] initWithSpelling:theSpelling ofType:code atPosition:0] forKey:theSpelling];
    [_spellingTable setObject:theSpelling forKey:[NSNumber numberWithInt:code]];
     
    _dictionaryChanged = YES;
}

-(NSString* )description
{
    return [[NSString alloc]initWithFormat:@"Parser v%d%s, %ld items",
            _dictionaryVersion, _dictionaryChanged ? ", modified" : "", [_dictionary count]];
    
}
#pragma mark - Token buffer management


//
//	Diagnostic routine that dumps out the token buffer.
//
-(void) dump {
    long len = [self count];
    NSLog(@"Token buffer:");
    for( int i = 0; i < len; i++ ) {
        NSLog(@"[%2d]: %@", i, [tokenList objectAtIndex:i]);
    }
}


//
//	Get the current position in the token buffer
//
-(long) position {
    return tokenPosition;
}

//
//	Set the current position in the token buffer.
//
-(void) setPosition:(long) newPosition {
    if( newPosition >= 0 | newPosition < [tokenList count])
        tokenPosition = newPosition;
    else
        tokenPosition = (long)[tokenList count] + 1;
}
//
//	Get the next token in the buffer.
//
-(int) nextToken {
    if( tokenPosition < [tokenList count]) {
        lastToken = [tokenList objectAtIndex:tokenPosition++];
        return [lastToken type];
    }
    lastToken = [[TCToken alloc] initWithSpelling:@"<end-of-string>" ofType:TOKEN_EOS atPosition:(long)[tokenList count]];
    return TOKEN_EOS;
    
    
}

//
//	Return the number of tokens (total) in the buffer.
//
-(long) count {
    return [tokenList count];
}

//
//	Test to see if the next token is a specific IDENTIFIER token
//
-(BOOL) isNextIdentifier:(NSString *) testSpelling {
    return [self isNextToken:testSpelling ofType:TOKEN_IDENTIFIER];
}

-(BOOL) isNextSpecial:(NSString *) testSpelling {
    return [self isNextToken:testSpelling ofType:TOKEN_SPECIAL];
}

/**
 Test to see if the next token matches the given spelling and type
 
 @param testSpelling the string we are to match (case-sensitive)
 @param testType the type of token we are expecting.  This lets
 the caller differentiate between an identifier and a quoted
 string, for example
 @returns true if the next token matches, in which case the token
 becomes the "last token" and the token pointer advances.  Returns
 false if it does not match, and the token pointer is not changed.
 */
-(BOOL) isNextToken:(NSString*) testSpelling ofType:(int) testType {
    
    TCToken *t = [tokenList objectAtIndex:tokenPosition];
    if([t type] == testType && testType == TOKEN_EOS) {
        tokenPosition++;
        lastToken = t;
        return YES;
    }
    if([t type] == testType && [[t spelling] compare:testSpelling]) {
        tokenPosition++;
        lastToken = t;
        return YES;
    }
    return NO;
}

/**
 Test to see if the next token in the token queue is a specific token
 type.
 
 @param ofType the type of token being tested for.
 @return true if the token matches.  The matched token becomes the
 "last token processed.  Returns false if the token does not match,
 and the token position is not moved.
 */

-(BOOL) isNextToken:(int) ofType {
    if(tokenPosition >= [tokenList count])
        return NO;
    
    TCToken *t = [tokenList objectAtIndex:tokenPosition];
    if([t type] == ofType) {
        tokenPosition++;
        lastToken = t;
        return YES;
    }
    return NO;
}

-(BOOL) isAtEnd
{
    if( tokenPosition >= tokenList.count)
        return YES;
    return NO;
}
//
//	Peek at the next token without advancing
//
-(int) peek {
    lastToken = [tokenList objectAtIndex:tokenPosition];
    return [lastToken type];
}

#pragma mark - Error handling


-(void) error:(TCErrorType)code
{
    _error = [[TCError alloc]initWithCode:code inSource:buffer atPosition:lastToken.position];
}

#pragma mark - Tokenization processing

/** 
 Given a string, break it down into lexical elements ready for parsing.
 @param string the NSString * buffer to be tokenized
 @return a count of the number of tokens found
 */

-(long) lex:(NSString*) string {
    
    
    scanner = [[NSScanner alloc] initWithString:string];
    buffer = [string copy];
    
    tokenList = [[NSMutableArray alloc] init];
    int count = 0;
    
    
    
    charPos = 0;
    
    while( [self lexNext]) {
        count++;
        TCToken *o = [_dictionary objectForKey:[lastToken spelling]];
        if( o != nil )
            [lastToken setType:[o type]];
    }
    tokenPosition = 0;
    charPos = -1;
    return count;
}

/**
 Lex the next item, and add it to the queue.  This is called in a loop from the
 lex: method to break out each individual item.  This is where syntactic features
 must be implemented, such as identifying what multi-character special character
 tokens we care about.
 @returns true if there is another token to process, else false if we have hit the
 end of the buffer
 */

-(BOOL) lexNext {
    
    long len = [buffer length];
    if( charPos >= len )
        return NO;
    
    // Skip leading whitepace.
    
    while( YES ) {
        if( charPos >= len)
            return NO;
        if( !isspace([buffer characterAtIndex:charPos]))
            break;
        charPos++;
    }
    
    int ch = [buffer characterAtIndex:charPos];
    NSRange r;
    r.location = charPos;
    r.length = 1;
    lastToken = [[TCToken alloc]init];
    [lastToken setPosition:charPos];
    
    // Check for leading "+" or "-" characters that would be eaten as
    // part of check for valid double or integer values.
    
    if( ch == '-' || ch == '+') {
        charPos++;
        [lastToken setSpelling:[NSString stringWithFormat:@"%c", ch]];
        [tokenList addObject:lastToken];
        return true;

    }

    //	Is it a double?
    [scanner setScanLocation:charPos];
    double double_value;
    if( [scanner scanDouble:&double_value]) {
        r.length = ([scanner scanLocation] - charPos)+1;
        charPos = [scanner scanLocation];
        
        // Does the resulting string contain characters
        // that show that it was really a double vs. integer?
        
        NSRange tempRange = r;
        tempRange.length--;
        BOOL isInteger = YES;
        NSString * doubleSpelling =  [buffer substringWithRange:tempRange];
        for( int cx = 0; cx < [doubleSpelling length]; cx++) {
            ch = [doubleSpelling characterAtIndex:cx];
            if( ch == '.' || ch == 'e' || ch == 'E') {
                isInteger = NO;
                break;
            }
        }
        //NSLog(@"Scanned a double, spelling = \"%@\", isInteger=%d", doubleSpelling, isInteger);
        
        if( isInteger && (double_value == (int)double_value)) {
            [lastToken setType:TOKEN_INTEGER];
        }
        else {
            [lastToken setType:TOKEN_DOUBLE];
        }
    }
    else
        //	Is it a integer string?
        if( isdigit(ch)) {
            while( YES ) {
                if( charPos >= len)
                    break;
                if( !isdigit([buffer characterAtIndex:charPos]))
                    break;
                
                r.length++;
                charPos++;
            }
            [lastToken setType:TOKEN_INTEGER];
        }
        else
            // Is it a quoted string?
            if( ch == '\'' || ch == '"') {
                charPos++;
                r.location++;
                while( YES ) {
                    if( charPos >= len)
                        break;
                    if( ch == [buffer characterAtIndex:charPos])
                        break;
                    
                    r.length++;
                    charPos++;
                }
                charPos++; /* Skip past the quote character */
                [lastToken setType:TOKEN_STRING];
            }
            else if( isalnum(ch)) {
                
                // An IDENTIFIER object, scan until white space or end of string
                while( YES ) {
                    if( charPos >= len)
                        break;
                    char idChar = [buffer characterAtIndex:charPos];
                    if( isalpha(idChar) || (idChar == '_')) {
                        r.length++;
                        charPos++;
                        
                    } else {
                        break;
                    }
                }
                [lastToken setType:TOKEN_IDENTIFIER];
            }
            else {
                // Handle case of special character strings that are made up of
                // multiple bytes
                long complexTokenLength = 0;
                for (NSString * key in _dictionary) {
                    TCToken * aToken = [_dictionary objectForKey:key];
                     NSString * testSpelling = aToken.spelling;
                    long testTokenLength = [testSpelling length];
                    if( charPos + testTokenLength > [buffer length] ) {
                        continue;
                    }
                    NSRange testTokenPosition = NSMakeRange( charPos, testTokenLength);
                    NSString * testString = [buffer substringWithRange:testTokenPosition];
                    
                    // If the token matches AND is longer than any previously found match, use it.
                    // This is needed to find ">=" instead of just ">", etc.
                    
                    if( [testSpelling isEqualToString:testString]) {
                        if(testTokenLength == complexTokenLength) {
                            NSLog(@"Warning, ambiguious or duplicate token");
                            continue;
                        }
                        if(testTokenLength < complexTokenLength) {
                            continue;
                        }
                        complexTokenLength = testTokenLength;
                    }
                }
                
                if( complexTokenLength) {
                    // It was a complex token, update the length and range appropriately
                    [lastToken setType:TOKEN_SPECIAL];
                    charPos += complexTokenLength;
                    r.length += complexTokenLength;
                } else {
                    // Who knows, just return the character.
                    [lastToken setType:TOKEN_SPECIAL];
                    charPos++;
                    r.length++;
                }
            }
    
    r.length--;
    if([lastToken type] == TOKEN_IDENTIFIER)
        [lastToken setSpelling:[buffer substringWithRange:r]];
    else
        [lastToken setSpelling:[buffer substringWithRange:r]];
    [tokenList addObject:lastToken];
    return true;
    
}

-(TokenType) lastTokenType
{
    return lastToken.type;
}

-(NSString*) lastSpelling
{
    return lastToken.spelling;
}
@end
