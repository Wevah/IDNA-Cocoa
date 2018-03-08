//
//  Controller.m
//  Punycode
//
//  Created by Wevah on Wed Feb 02 2005.
//  Copyright (c) 2005 Derailer. All rights reserved.
//

#import "Controller.h"
#import "NSStringPunycodeAdditions.h"


@interface Controller ()

@property (weak)	IBOutlet NSTextField	*normalField;
@property (weak)	IBOutlet NSTextField	*idnField;

@end

@implementation Controller

- (void)awakeFromNib {
#if PUNYCODE_COCOA_USE_WEBKIT
#	define PUNYCODE_COCOA_LIBNAME @"WebKit"
#elif PUNYCODE_COCOA_USE_ICU
#	define PUNYCODE_COCOA_LIBNAME @"ICU"
#else
#	define PUNYCODE_COCOA_LIBNAME @"custom"
#endif

	self.window.title = [NSString stringWithFormat:@"%@ (%@)", self.window.title, PUNYCODE_COCOA_LIBNAME];
}

- (IBAction)stringToIDNA:(id)sender {
	self.idnField.stringValue = [sender stringValue].encodedURLString;
}

- (IBAction)stringFromIDNA:(id)sender {
	self.normalField.stringValue = [sender stringValue].decodedURLString;
}

@end
