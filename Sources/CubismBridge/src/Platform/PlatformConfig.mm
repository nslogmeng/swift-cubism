//
//  PlatformConfig.mm
//  Cubism
//
//  Created by Meng on 2025/8/25.
//

#import "PlatformConfig.h"

@implementation PlatformConfig

static LoadFileHandler _loadFileHandler = nil;
static LogHandler _logHandler = nil;
static CubismLogLevel _logLevel = CubismLogLevelInfo;

+ (id<MTLDevice>)MTLDevice {
    static id<MTLDevice> device = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        device = MTLCreateSystemDefaultDevice();
    });
    return device;
}

+ (LoadFileHandler)loadFileHandler {
    return _loadFileHandler;
}

+ (void)setLoadFileHandler:(LoadFileHandler)loadFileHandler {
    _loadFileHandler = loadFileHandler;
}

+ (LogHandler)logHandler {
    return _logHandler;
}

+ (void)setLogHandler:(LogHandler)logHandler {
    _logHandler = logHandler;
}

+ (CubismLogLevel)logLevel {
    return _logLevel;
}

+ (void)setLogLevel:(CubismLogLevel)logLevel {
    _logLevel = logLevel;
}

@end
