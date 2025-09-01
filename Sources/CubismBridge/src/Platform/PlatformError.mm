//
//  PlatformError.m
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import "PlatformError.h"

NSString * const CubismErrorDomain = @"com.cubism.bridge.error";

@implementation PlatformError

+ (NSError *)errorWithCode:(CubismErrorCode)code {
    return [NSError errorWithDomain:CubismErrorDomain code:code userInfo:nil];
}

@end
