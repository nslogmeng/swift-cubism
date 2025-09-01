//
//  Live2DModelSetting.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import <Foundation/Foundation.h>
#import <ICubismModelSetting.hpp>
#import "Live2DModelSetting.h"

NS_ASSUME_NONNULL_BEGIN

@interface Live2DModelSetting(Internal)

@property (nonatomic, assign, readonly) Csm::ICubismModelSetting *modelSetting;

@end

NS_ASSUME_NONNULL_END
