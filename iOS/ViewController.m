//
//  ViewController.m
//  PunyCocoaTouch
//
//  Created by Nate Weaver on 2019-06-12.
//

#import "ViewController.h"
#import "PunyCocoaTouch-Swift.h"

@interface ViewController ()

@property (weak)	IBOutlet	UITextField	*unicodeField;
@property (weak)	IBOutlet	UITextField	*idnaField;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (IBAction)convertFromUnicode:(UITextField *)sender {
	NSString *str = sender.text;
	self.idnaField.text = str.encodedURLString;
}

- (IBAction)convertFromIDNA:(UITextField *)sender {
	NSString *str = sender.text;
	self.unicodeField.text = str.decodedURLString;
}

@end
