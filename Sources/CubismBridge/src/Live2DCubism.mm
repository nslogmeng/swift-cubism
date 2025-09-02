//
//  Live2DCubism.m
//  Cubism
//
//  Created by Meng on 2025/8/26.
//

#import "CubismFramework.hpp"
#import "Live2DCubism.h"
#import "Platform/PlatformAllocator.h"
#import "Platform/PlatformConfig.h"
#import "Platform/PlatformOption.h"
#import <Rendering/Metal/CubismRenderingInstanceSingleton_Metal.h>
#import <string.h>

using namespace std;
using namespace Live2D::Cubism::Framework;

@interface Live2DCubism()

@property (nonatomic) PlatformAllocator allocator;
@property (nonatomic) Csm::CubismFramework::Option option;

@end

@implementation Live2DCubism

+ (Live2DCubism *)shared {
    static Live2DCubism *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Live2DCubism alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _option.LogFunction = PlatformOption::PrintLog;
    _option.LoggingLevel = static_cast<CubismFramework::Option::LogLevel>(PlatformConfig.logLevel);
    _option.LoadFileFunction = PlatformOption::LoadFileAsBytes;
    _option.ReleaseBytesFunction = PlatformOption::ReleaseBytes;
}

- (void)start {
    Csm::CubismFramework::StartUp(&_allocator, &_option);
    Csm::CubismFramework::Initialize();

    // set framework shared MTLDevice
    CubismRenderingInstanceSingleton_Metal *single = [CubismRenderingInstanceSingleton_Metal sharedManager];
    [single setMTLDevice:PlatformConfig.MTLDevice];
}

- (void)stop {
    Csm::CubismFramework::Dispose();
    Csm::CubismFramework::CleanUp();
}

- (void)dealloc {
    Csm::CubismFramework::Dispose();
    Csm::CubismFramework::CleanUp();
}

@end
