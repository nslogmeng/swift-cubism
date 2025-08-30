//
//  Live2DModelSetting.mm
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import "Live2DModelSetting.h"
#import "Live2DModelSetting+Internal.h"
#import "../Platform/PlatformOption.h"
#import <Type/CubismBasicType.hpp>
#import <Type/csmString.hpp>
#import <CubismModelSettingJson.hpp>

using namespace Live2D::Cubism::Framework;

@interface Live2DModelSetting()

@property (nonatomic, copy, readwrite) NSString *homeDir;
@property (nonatomic, copy, readwrite) NSString *fileName;
@property (nonatomic, assign, readwrite) Csm::ICubismModelSetting *setting;

@end

@implementation Live2DModelSetting

- (instancetype)initWithHomeDir:(NSString *)homeDir fileName:(NSString *)fileName {
    self = [super init];
    if (self) {
        self.homeDir = homeDir;
        self.fileName = fileName;
        self.setting = [self buildSetting];
    }
}

- (Csm::ICubismModelSetting *)buildSetting {
    NSString *settingFilePath = [self.homeDir stringByAppendingPathComponent:self.fileName];
    csmSizeInt size;
    const csmString path = [settingFilePath cStringUsingEncoding:NSUTF8StringEncoding];

    csmByte *buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
    ICubismModelSetting *setting = new CubismModelSettingJson(buffer, size);
    PlatformOption::ReleaseBytes(buffer);

    return setting;
}

- (void)dealloc {
    delete _setting;
}

@end
