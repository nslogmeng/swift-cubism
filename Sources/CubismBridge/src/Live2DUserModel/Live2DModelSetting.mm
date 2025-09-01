//
//  Live2DModelSetting.mm
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import "Live2DModelSetting.h"
#import "Live2DModelSetting+Internal.h"
#import "Platform/PlatformError.h"
#import "Platform/PlatformOption.h"
#import <Type/CubismBasicType.hpp>
#import <Type/csmString.hpp>
#import <CubismModelSettingJson.hpp>

using namespace Live2D::Cubism::Framework;

@interface Live2DModelSetting()

@property (nonatomic, copy, readwrite) NSString *homeDir;
@property (nonatomic, copy, readwrite) NSString *fileName;
@property (nonatomic, assign, readwrite) Csm::ICubismModelSetting *modelSetting;

@end

@implementation Live2DModelSetting

- (nullable instancetype)initWithHomeDir:(NSString *)homeDir
                                fileName:(NSString *)fileName
                                   error:(NSError **)error {
    self = [super init];
    if (self) {
        _homeDir = homeDir;
        _fileName = fileName;
        _modelSetting = [self buildModelSettingWithError:error];

        if ((error && *error) || (_modelSetting == NULL)) {
            return nil;
        }
    }
    return self;
}

- (Csm::ICubismModelSetting *)buildModelSettingWithError:(NSError **)error {
    NSString *settingFilePath = [self.homeDir stringByAppendingPathComponent:self.fileName];

    if (![[NSFileManager defaultManager] fileExistsAtPath:settingFilePath]) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeModelSettingFileNotFound];
        }
        return NULL;
    }

    csmSizeInt size;
    const csmString path = [settingFilePath cStringUsingEncoding:NSUTF8StringEncoding];

    csmByte *buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
    CubismModelSettingJson *modelSetting = new CubismModelSettingJson(buffer, size);
    PlatformOption::ReleaseBytes(buffer);

    if (!modelSetting->IsValid()) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeModelSettingJSONInvalid];
        }
        delete modelSetting; // release modelSetting
        return NULL;
    }

    return modelSetting;
}

- (void)dealloc {
    delete _modelSetting;
}

@end
