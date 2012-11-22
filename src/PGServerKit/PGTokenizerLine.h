
#import <Foundation/Foundation.h>
#import "PGTokenizer.h"

@interface PGTokenizerLine : NSObject {
	NSUInteger _state;
	NSMutableString* _text;
	BOOL _enabled;
	NSString* _keyword;
	NSMutableString* _value;
	NSMutableString* _comment;
}

@property (readonly) NSString* keyword;
@property (readonly) NSString* comment;
@property (retain) NSString* value;
@property (assign) BOOL enabled;

@end