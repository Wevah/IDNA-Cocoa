//
//  Controller.m
//  Punycode
//
//  Created by Wevah on Wed Feb 02 2005.
//  Copyright (c) 2005 Derailer. All rights reserved.
//

#import "Controller.h"
#import "PunyCocoa_ObjC-Swift.h"

@interface Controller ()

@property (weak)	IBOutlet NSTextField	*normalField;
@property (weak)	IBOutlet NSTextField	*idnField;

@end

@implementation Controller

- (void)awakeFromNib {
	self.window.title = [NSString stringWithFormat:@"%@ (ObjC)", self.window.title];
}

- (IBAction)stringToIDNA:(id)sender {
	self.idnField.stringValue = [sender stringValue].encodedURLString;
}

- (IBAction)stringFromIDNA:(id)sender {
	self.normalField.stringValue = [sender stringValue].decodedURLString;
}

@end
