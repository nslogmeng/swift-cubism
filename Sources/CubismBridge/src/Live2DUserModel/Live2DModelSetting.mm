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

        // 模型配置文件
        _configFilePath = [self parseConfigFilePathWithError:error];
        if (!_configFilePath || (error && *error)) {
            return nil;
        }
        // 模型配置 JSON
        _modelSetting = [self parseModelSettingWithError:error];
        if ((_modelSetting == NULL) || (error && *error)) {
            return nil;
        }

        // Cubism 模型文件
        _modelFilePath = [self parseCubismModelFilePathWithError:error];
        if (!_modelFilePath || (error && *error)) {
            return nil;
        }
        // Texture 纹理文件
        _textureFilePaths = [self parseTextureFilePathsWithError:error];
        if (!_textureFilePaths || (error && *error)) {
            return nil;
        }

        // 表情文件
        _expressionFilePaths = [self parseExpressionFilePaths];
        // 物理文件
        _phyicsFilePath = [self parsePhysicsFilePath];
        // 姿势文件
        _poseFilePath = [self parsePoseFilePath];

        // 用户数据文件
        _userDataFilePath = [self parseUserDataFilePath];
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

/// 模型设置 JSON 解析
- (Csm::ICubismModelSetting *)parseModelSettingWithError:(NSError **)error {
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

// Cubism 模型文件（必选）
- (nullable NSString *)parseCubismModelFilePathWithError:(NSError **)error {
    const csmChar *cFileName = _modelSetting->GetModelFileName();
    NSString *fileName = [NSString stringWithCString:cFileName encoding:NSUTF8StringEncoding];

    if (fileName.length == 0) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeModelFileNotFound];
            return nil;
        }
    }

    NSString *filePath = [_homeDir stringByAppendingPathComponent: fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:_modelFilePath]) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeModelFileNotFound];
        }
        return nil;
    }

    return filePath;
}

/// 纹理文件（必选）
- (NSArray<NSString *> *)parseTextureFilePathsWithError:(NSError **)error {
    const csmInt32 textureCount = _modelSetting->GetTextureCount();
    NSMutableArray<NSString *> *textureFilePaths = [NSMutableArray array];
    for (csmInt32 textureNumber = 0; textureNumber < textureCount; textureNumber++) {
        const csmChar *cFileName = _modelSetting->GetTextureFileName(textureNumber);
        NSString *fileName = [NSString stringWithCString:cFileName encoding:NSUTF8StringEncoding];
        NSString *filePath = [_homeDir stringByAppendingPathComponent:fileName];

        [textureFilePaths addObject:filePath];
    }
    if (textureCount <= 0 || textureFilePaths.count <= 0) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeNoValidTextureFile];
        }
        return @[];
    }
    return textureFilePaths;
}

/// 动作文件
- (NSDictionary<NSString *, NSString *> *)parseMotionFilePaths {
    const csmInt32 groupCount = _modelSetting->GetMotionGroupCount();
    if (groupCount <= 0) {
        return @{};
    }

    NSMutableDictionary<NSString *, NSString *> *motionFilePath = [NSMutableDictionary dictionary];
    for (csmInt32 i = 0; i < groupCount; i++) {
        const csmChar *groupName = _modelSetting->GetMotionGroupName(i);
        const csmInt32 motionCount = _modelSetting->GetMotionCount(groupName);
        for (csmInt32 i = 0; i < motionCount; i++) {
            const csmChar *cFileName = _modelSetting->GetMotionFileName(groupName, i);
            NSString *motionName = [NSString stringWithFormat:@"%s_%d", groupName, i];
            NSString *fileName = [NSString stringWithCString:cFileName encoding:NSUTF8StringEncoding];
            NSString *filePath = [_homeDir stringByAppendingPathComponent:fileName];

            [motionFilePath setObject:filePath forKey:motionName];
        }
    }

    return motionFilePath;
}

/// 表情文件
- (NSDictionary<NSString *, NSString *> *)parseExpressionFilePaths {
    const csmInt32 count = _modelSetting->GetExpressionCount();
    if (count <= 0) {
        return @{};
    }

    NSMutableDictionary<NSString *, NSString *> *expressionPaths = [NSMutableDictionary dictionary];
    for (csmInt32 i = 0; i < count; i++) {
        const csmChar *cName = _modelSetting->GetExpressionName(i);
        const csmChar *cFileName = _modelSetting->GetExpressionFileName(i);
        NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
        NSString *fileName = [NSString stringWithCString:cFileName encoding:NSUTF8StringEncoding];
        NSString *filePath = [_homeDir stringByAppendingPathComponent:fileName];

        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            continue;
        }

        [expressionPaths setObject:filePath forKey:name];
    }
    return expressionPaths;
}

/// 物理文件
- (nullable NSString *)parsePhysicsFilePath {
    const csmChar *cFileName = _modelSetting->GetPhysicsFileName();
    NSString *fileName = [NSString stringWithCString:cFileName encoding:NSUTF8StringEncoding];
    if (fileName.length <= 0) {
        return nil;
    }

    NSString *filePath = [_homeDir stringByAppendingPathComponent:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return nil;
    }

    return filePath;
}

/// 姿势文件
- (nullable NSString *)parsePoseFilePath {
    const csmChar *cFileName = _modelSetting->GetPoseFileName();
    NSString *fileName = [NSString stringWithCString:cFileName encoding:NSUTF8StringEncoding];
    if (fileName.length <= 0) {
        return nil;
    }

    NSString *filePath = [_homeDir stringByAppendingPathComponent:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return nil;
    }

    return filePath;
}

/// 用户数据文件
- (nullable NSString *)parseUserDataFilePath {
    const csmChar *cFileName = _modelSetting->GetUserDataFile();
    NSString *fileName = [NSString stringWithCString:cFileName encoding:NSUTF8StringEncoding];
    if (fileName.length <= 0) {
        return nil;
    }

    NSString *filePath = [_homeDir stringByAppendingPathComponent:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return nil;
    }

    return filePath;
}

- (void)dealloc {
    delete _modelSetting;
}

@end
