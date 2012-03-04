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
	NSString *str;
	NSString *encoded;
	
	str = @"bücher";
	encoded = @"bcher-kva";
	STAssertTrue([[str punycodeEncodedString] isEqualToString:encoded], @"%@ should encode to %@", str, encoded);
	
	str = @"президент";
	encoded = @"d1abbgf6aiiy";
	STAssertTrue([[str punycodeEncodedString] isEqualToString:encoded], @"%@ should encode to %@", str, encoded);
}

- (void)testPunycodeDecoding {
	NSString *str;
	NSString *decoded;
	
	str = @"bcher-kva";
	decoded = @"bücher";
	STAssertTrue([[str punycodeDecodedString] isEqualToString:decoded], @"%@ should decode to %@", str, decoded);
	
	str = @"d1abbgf6aiiy";
	decoded = @"президент";
	STAssertTrue([[str punycodeDecodedString] isEqualToString:decoded], @"%@ should decode to %@", str, decoded);
}


@end
