//
//  NSStringPunycodeAdditions.h
//  Punycode
//
//  Created by Wevah on 2005.11.02.
//  Copyright 2005 Derailer. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (PunycodeAdditions)

- (NSString *)punycodeEncodedString;
- (NSString *)punycodeDecodedString;

// These methods currently expect self to start with a valid scheme.
- (NSString *)IDNAEncodedString;
- (NSString *)IDNADecodedString;
- (NSString *)encodedURLString;
- (NSString *)decodedURLString;

@end

@interface NSURL (PunycodeAdditions)

- (NSString *)decodedURLString;

@end
