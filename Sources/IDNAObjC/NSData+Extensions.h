//
//  NSData+Extensions.h
//  
//
//  Created by Nate Weaver on 2021-05-12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (Extensions)

@property (readonly) uint32_t CRC32;

@end

NS_ASSUME_NONNULL_END
