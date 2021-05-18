//
//  NSString+IDNA.h
//  
//
//  Created by Nate Weaver on 2021-05-18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (IDNA)

@property (nonatomic, nullable, readonly) NSString *IDNAEncoded;
@property (nonatomic, nullable, readonly) NSString *IDNADecoded;
@property (nonatomic, nullable, readonly) NSString *encodedURLString;
@property (nonatomic, nullable, readonly) NSString *decodedURLString;

@end

@interface NSURL (IDNA)

- (nullable instancetype)URLWithUnicodeString:(NSString *)string;

@property (nonatomic, nullable, readonly) NSString *decodedURLString;

- (nullable instancetype)URLWithUnicodeString:(NSString *)string relativeToURL:(nullable NSURL *)url;

@end

NS_ASSUME_NONNULL_END
