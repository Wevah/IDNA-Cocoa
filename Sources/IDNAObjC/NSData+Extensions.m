//
//  NSData+Extensions.m
//  
//
//  Created by Nate Weaver on 2021-05-12.
//

#import "NSData+Extensions.h"
#import <zlib.h>

@implementation NSData (Extensions)

- (uint32_t)CRC32 {
	uLong initial = crc32(0, NULL, 0);
	return (uint32_t)crc32(initial, self.bytes, (uInt)self.length);
}

@end
