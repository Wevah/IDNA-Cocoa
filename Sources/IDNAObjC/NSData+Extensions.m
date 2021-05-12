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
	uint32_t initial = crc32(0, NULL, 0);
	return crc32(initial, self.bytes, self.length);
}

@end
