//
//  PlatformError.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CubismErrorDomain;

typedef NS_ENUM(NSInteger, CubismErrorCode) {
    /// 未知错误
    CubismErrorCodeUnknown = 0,
    /// 模型设置文件找不到
    CubismErrorCodeModelSettingFileNotFound = 1,
    /// 模型 JSON 不合法
    CubismErrorCodeModelSettingJSONInvalid = 2
};

@interface PlatformError : NSObject

+ (NSError *)errorWithCode:(CubismErrorCode)code;

@end

NS_ASSUME_NONNULL_END
