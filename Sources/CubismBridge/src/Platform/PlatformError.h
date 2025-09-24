//
//  PlatformError.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CubismErrorDomain;

typedef NS_ENUM(NSInteger, CubismErrorCode) {
    /// 未知错误
    CubismErrorCodeUnknown = 0,

    /// 模型根目录找不到
    CubismErrorCodeModelHomeDirectoryNotFound = 100,
    /// 模型根路径不是 directory
    CubismErrorCodeModelHomeIsNotDirectory = 101,
    /// 模型设置文件找不到
    CubismErrorCodeModelConfigFileNotFound = 102,
    /// 模型设置文件 JSON 不合法
    CubismErrorCodeModelConfigJSONInvalid = 103,
    /// 模型文件找不到
    CubismErrorCodeModelFileNotFound = 104,
    /// 没有配置或无合法的纹理文件
    CubismErrorCodeNoValidTextureFile = 105,

    /// 加载 Cubism 模型文件失败
    CubismErrorCodeLoadCubismModelFailed = 201,
    /// 纹理加载失败
    CubismErrorCodeLoadTextureFailed = 202,
};

@interface PlatformError : NSObject

+ (NSError *)errorWithCode:(CubismErrorCode)code;

@end

NS_ASSUME_NONNULL_END
