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

/// 模型配置文件路径
@property (nonatomic, copy, readwrite) NSString *configFilePath;
/// 模型文件路径
@property (nonatomic, copy, readwrite) NSString *modelFilePath;

/// 纹理文件路径
@property (nonatomic, copy, readwrite) NSArray<NSString *> *textureFilePaths;
/// 动作文件 map<name, path(.motion3.json)>
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSString *> *motionFilePaths;
/// 表情文件 map<name, path(.exp3.json)>
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSString *> *expressionFilePaths;
/// 物理文件路径 (.physics3.json)
@property (nullable, nonatomic, copy, readwrite) NSString *phyicsFilePath;
/// 姿势文件路径 (.pose3.json)
@property (nullable, nonatomic, copy, readwrite) NSString *poseFilePath;

/// UserData 文件路径 (.userdata3.json)
@property (nullable, nonatomic, copy, readwrite) NSString *userDataFilePath;

@property (nonatomic, assign, readwrite) Csm::ICubismModelSetting *modelSetting;

@end

@implementation Live2DModelSetting

- (nullable instancetype)initWithHomeDir:(NSString *)homeDir error:(NSError **)error {
    self = [super init];
    if (self) {
        _homeDir = [homeDir copy];

        _configFilePath = [self parseConfigFilePathWithError:error];
        if (!_configFilePath || (error && *error)) {
            return nil;
        }

        _modelSetting = [self buildModelSettingWithError:error];
        if ((_modelSetting == NULL) || (error && *error)) {
            return nil;
        }

        BOOL result = [self parseFilesWithError:error];
        if (!result || (error && *error)) {
            return nil;
        }
    }
    return self;
}

- (NSString *)parseConfigFilePathWithError:(NSError **)error {
    // check home dir
    BOOL homeIsDir;
    BOOL homeExist = [[NSFileManager defaultManager] fileExistsAtPath:_homeDir isDirectory:&homeIsDir];
    if (!homeExist) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeModelHomeDirectoryNotFound];
        }
        return nil;
    }
    if (!homeIsDir) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeModelHomeIsNotDirectory];
        }
        return nil;
    }

    // find config filePath
    NSArray<NSString *> *subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_homeDir error:nil];
    if (!subpaths || subpaths.count <= 0) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeModelConfigFileNotFound];
        }
        return nil;
    }
    NSString *configFilePath;
    for (NSString *fileName in subpaths) {
        if (![fileName hasSuffix:@".model3.json"]) {
            continue;
        }
        configFilePath = [_homeDir stringByAppendingPathComponent:fileName];
        break;
    }

    if (!configFilePath || ![[NSFileManager defaultManager] fileExistsAtPath:configFilePath]) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeModelConfigFileNotFound];
        }
        return nil;
    }

    return configFilePath;
}

- (Csm::ICubismModelSetting *)buildModelSettingWithError:(NSError **)error {
    csmSizeInt size;
    const csmString path = [_configFilePath cStringUsingEncoding:NSUTF8StringEncoding];

    csmByte *buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
    CubismModelSettingJson *modelSetting = new CubismModelSettingJson(buffer, size);
    PlatformOption::ReleaseBytes(buffer);

    if (!modelSetting->IsValid()) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeModelConfigJSONInvalid];
        }
        delete modelSetting; // release modelSetting
        return NULL;
    }

    return modelSetting;
}

- (void)dealloc {
    delete _modelSetting;
}

- (BOOL)parseFilesWithError:(NSError **)error {
    // Cubism 模型
    if (strcmp(_modelSetting->GetModelFileName(), "") != 0) {
        const csmChar *_fileName = _modelSetting->GetModelFileName();
        NSString *fileName = [NSString stringWithCString:_fileName encoding:NSUTF8StringEncoding];
        _modelFilePath = [_homeDir stringByAppendingPathComponent: fileName];

        // 模型文件必选
        if (![[NSFileManager defaultManager] fileExistsAtPath:_modelFilePath]) {
            if (error) {
                *error = [PlatformError errorWithCode:CubismErrorCodeModelFileNotFound];
            }
            return NO;
        }
    }

    // 纹理
    csmInt32 textureCount = _modelSetting->GetTextureCount();
    NSMutableArray<NSString *> *tmpTextureFilePaths = [NSMutableArray array];
    for (csmInt32 textureNumber = 0; textureNumber < textureCount; textureNumber++) {
        const csmChar *_fileName = _modelSetting->GetTextureFileName(textureNumber);
        NSString *fileName = [NSString stringWithCString:_fileName encoding:NSUTF8StringEncoding];
        NSString *filePath = [_homeDir stringByAppendingPathComponent:fileName];

        [tmpTextureFilePaths addObject:filePath];
    }
    if (textureCount <= 0 || tmpTextureFilePaths.count <= 0) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeNoValidTextureFile];
        }
        return NO;
    }
    _textureFilePaths = tmpTextureFilePaths;

    // 表情
    _expressionFilePaths = @{};
    if (_modelSetting->GetExpressionCount() > 0) {
        NSMutableDictionary<NSString *, NSString *> *tmpExpressionPaths = [NSMutableDictionary dictionary];
        const csmInt32 count = _modelSetting->GetExpressionCount();
        for (csmInt32 i = 0; i < count; i++) {
            const csmChar *_name = _modelSetting->GetExpressionName(i);
            const csmChar *_fileName = _modelSetting->GetExpressionFileName(i);
            NSString *name = [NSString stringWithCString:_name encoding:NSUTF8StringEncoding];
            NSString *fileName = [NSString stringWithCString:_fileName encoding:NSUTF8StringEncoding];
            NSString *filePath = [_homeDir stringByAppendingPathComponent:fileName];

            if ([name isEqualToString:@""]) {
                continue;
            }

            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                continue;
            }

            [tmpExpressionPaths setObject:filePath forKey:name];
        }
        _expressionFilePaths = tmpExpressionPaths;
    }

    return YES;
}

@end
