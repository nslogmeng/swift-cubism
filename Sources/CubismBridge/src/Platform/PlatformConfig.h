//
//  PlatformConfig.h
//  Cubism
//
//  Created by Meng on 2025/8/25.
//

#import <Foundation/Foundation.h>
#import <Metal/MTLDevice.h>

NS_ASSUME_NONNULL_BEGIN

/// 平台注入 Log level
typedef NS_ENUM(NSInteger, CubismLogLevel) {
    CubismLogLevelVerbose = 0,
    CubismLogLevelDebug,
    CubismLogLevelInfo,
    CubismLogLevelWarning,
    CubismLogLevelError,
    CubismLogLevelOff
};

/// Cubism platform 配置
@interface PlatformConfig : NSObject

typedef NSData * _Nullable (^LoadFileHandler)(NSString *filePath);
typedef void (^LogHandler)(NSString *message);

/// shared MTLDevice
@property (class, nonatomic, readonly) id<MTLDevice> MTLDevice;

/// 文件加载 handler
@property (class, nonatomic, copy, nullable) LoadFileHandler loadFileHandler;

/// 日志 handler
@property (class, nonatomic, copy, nullable) LogHandler logHandler;
/// 日志 loglevel
@property (class, assign) CubismLogLevel logLevel;

@end

NS_ASSUME_NONNULL_END
