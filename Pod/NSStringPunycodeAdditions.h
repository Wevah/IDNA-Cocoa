//
//  NSStringPunycodeAdditions.h
//  Punycode
//
//  Created by Wevah on 2005.11.02.
//  Copyright 2005-2012 Derailer. All rights reserved.
//
//  Distributed under an MIT-style license; please
//  see the included LICENSE file for details.
//

#import <Foundation/Foundation.h>


@interface NSString (PunycodeAdditions)

@property (readonly, copy)	NSString *punycodeEncodedString;
@property (readonly, copy)	NSString *punycodeDecodedString;

@property (readonly, copy) NSString *IDNAEncodedString;
@property (readonly, copy) NSString *IDNADecodedString;

// These methods currently expect self to start with a valid scheme.
@property (readonly, copy) NSString *encodedURLString;
@property (readonly, copy) NSString *decodedURLString;

@end

@interface NSURL (PunycodeAdditions)

+ (instancetype)URLWithUnicodeString:(NSString *)URLString;
@property (readonly, copy) NSString *decodedURLString;

@end
