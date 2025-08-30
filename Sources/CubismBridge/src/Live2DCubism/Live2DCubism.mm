//
//  Live2DCubism.m
//  Cubism
//
//  Created by Meng on 2025/8/26.
//

#import "Live2DCubism.h"
#import "CubismFramework.hpp"
#import "Platform/Config/PlatformConfig.h"
#import "Platform/Allocator/PlatformAllocator.h"
#import "Platform/Option/PlatformOption.h"
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
}

- (void)stop {
    Csm::CubismFramework::Dispose();
    Csm::CubismFramework::CleanUp();
}

- (void)dealloc {
    Csm::CubismFramework::Dispose();
    Csm::CubismFramework::CleanUp();
    [super dealloc];
}

@end
