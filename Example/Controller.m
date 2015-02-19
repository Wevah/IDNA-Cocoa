//
//  Controller.m
//  Punycode
//
//  Created by Wevah on Wed Feb 02 2005.
//  Copyright (c) 2005 Derailer. All rights reserved.
//

#import "Controller.h"
#import "NSStringPunycodeAdditions.h"


@implementation Controller

- (IBAction)stringToIDNA:(id)sender {
	[idnField setStringValue:[[sender stringValue] encodedURLString]];
}

- (IBAction)stringFromIDNA:(id)sender {
	[normalField setStringValue:[[sender stringValue] decodedURLString]];
}

@end
