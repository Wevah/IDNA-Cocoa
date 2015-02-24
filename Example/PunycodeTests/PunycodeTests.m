//
//  PunycodeTests.m
//  PunycodeTests
//
//  Created by Nate Weaver on 3/2/12.
//  Copyright (c) 2012 Derailer. All rights reserved.
//

#import "PunycodeTests.h"
#import "NSStringPunycodeAdditions.h"

@implementation PunycodeTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testPunycodeEncoding {
	NSDictionary *dict = @{
						   @"bücher":		@"bcher-kva",
						   @"президент":	@"d1abbgf6aiiy",
						   @"例え":			@"r8jz45g"
						   };
	
	[dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
		XCTAssertTrue([key.punycodeEncodedString isEqualToString:obj], @"%@ should encode to %@", key, obj);
	}];
}

- (void)testPunycodeDecoding {
	NSDictionary *dict = @{
						   @"bcher-kva":	@"bücher",
						   @"d1abbgf6aiiy":	@"президент",
						   @"r8jz45g":		@"例え"
						   };
	
	[dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
		XCTAssertTrue([key.punycodeDecodedString isEqualToString:obj], @"%@ should decode to %@", key, obj);
	}];
}

- (void)testIDNAEncoding {
	NSDictionary *dict = @{
						   @"http://www.bücher.ch/":	@"http://www.xn--bcher-kva.ch/"
						   };
	[dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
		XCTAssertTrue([key.IDNAEncodedString isEqualToString:obj], @"%@ should encode to %@", key, obj);
	}];
}

- (void)testIDNDecoding {
	NSDictionary *dict = @{
						   @"http://www.xn--bcher-kva.ch/":	@"http://www.bücher.ch/"
						   };
	[dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
		XCTAssertTrue([key.IDNADecodedString isEqualToString:obj], @"%@ should decode to %@", key, obj);
	}];
}


@end
