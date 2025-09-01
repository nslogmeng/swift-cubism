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

    /// 模型根目录找不到
    CubismErrorCodeModelHomeDirectoryNotFound = 1,
    /// 模型根路径不是 directory
    CubismErrorCodeModelHomeIsNotDirectory = 2,

    /// 模型设置文件找不到
    CubismErrorCodeModelConfigFileNotFound = 3,
    /// 模型设置文件 JSON 不合法
    CubismErrorCodeModelConfigJSONInvalid = 4,

    /// 模型文件找不到
    CubismErrorCodeModelFileNotFound = 5,
    /// 没有配置或无合法的纹理文件
    CubismErrorCodeNoValidTextureFile = 6,

};

@interface PlatformError : NSObject

+ (NSError *)errorWithCode:(CubismErrorCode)code;

@end

NS_ASSUME_NONNULL_END
