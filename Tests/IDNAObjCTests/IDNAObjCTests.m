//
//  Test.m
//  
//
//  Created by Nate Weaver on 2021-05-18.
//

#import <XCTest/XCTest.h>
#import "NSString+IDNA.h"

@interface Test : XCTestCase

@end

@implementation Test

- (void)testGetFirstCodePoint {
	unichar first[2];
	NSString *str = @"foo";
	NSUInteger length;
	[str getFirstCodePoint:first length:&length];
	
}

@end
