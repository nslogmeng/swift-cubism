//
//  Live2DModelSetting.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import <Foundation/Foundation.h>
#import "Live2DModelSetting.h"
#import <Type/CubismBasicType.hpp>
#import <ICubismModelSetting.hpp>

NS_ASSUME_NONNULL_BEGIN

using namespace Live2D::Cubism::Framework;

@interface Live2DModelSetting(Internal)

@property (nonatomic, assign, readonly) Csm::ICubismModelSetting *modelSetting;

/// 模型配置文件
@property (nonatomic, copy, readonly) NSString *configFilePath;
/// 模型文件路径
@property (nonatomic, copy, readonly) NSString *modelFilePath;

/// 纹理文件路径
@property (nonatomic, copy, readonly) NSArray<NSString *> *textureFilePaths;
/// 动作文件 map<name, path(.motion3.json)>
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *motionFilePaths;
/// 表情文件 map<name, path(.exp3.json)>
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *expressionFilePaths;
/// 物理文件路径 (.physics3.json)
@property (nullable, nonatomic, copy, readonly) NSString *phyicsFilePath;
/// 姿势文件路径 (.pose3.json)
@property (nullable, nonatomic, copy, readonly) NSString *poseFilePath;

/// UserData 文件路径 (.userdata3.json)
@property (nullable, nonatomic, copy, readonly) NSString *userDataFilePath;

@end

NS_ASSUME_NONNULL_END
