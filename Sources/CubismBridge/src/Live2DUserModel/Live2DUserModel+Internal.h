//
//  Live2DUserModel.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import <Foundation/Foundation.h>
#import <ICubismModelSetting.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface Live2DUserModel(Internal)

/// 模型设置设置信息
@property (nonatomic, assign) Csm::ICubismModelSetting *modelSetting;

@end

NS_ASSUME_NONNULL_END
