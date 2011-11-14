//
//  NSStringPunycodeAdditions.h
//  Punycode
//
//  Created by Wevah on 2005.11.02.
//  Copyright 2005 Derailer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (PunycodeAdditions)

- (NSString *)punycodeEncodedString;
- (NSString *)punycodeDecodedString;

- (NSString *)IDNAEncodedString;
- (NSString *)IDNADecodedString;
- (NSString *)encodedURLString;
- (NSString *)decodedURLString;

//+ (void)setIDNACharacterBlacklist:(NSCharacterSet *)aSet;
//+ (NSCharacterSet *)IDNACharacterBlacklist;

@end

@interface NSURL (PunycodeAdditions)

- (NSString *)decodedURLString;

@end
