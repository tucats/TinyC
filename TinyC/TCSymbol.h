//
//  TCSymbol.h
//  Language
//
//  Created by Tom Cole on 4/1/14.
//
//

#import <Foundation/Foundation.h>
#import "TCValue.h"
#import "TCStorageManager.h"


@interface TCSymbol : NSObject

@property NSString * spelling;
@property TCValueType type;
@property int size;
@property BOOL allocated;
@property TCValue * initialValue;
@property int scope;
@property long address;

-(void) setValue:(TCValue*)value storage:(TCStorageManager*) storage;


@end
