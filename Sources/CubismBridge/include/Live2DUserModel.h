//
//  Live2DUserModel.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import <Foundation/Foundation.h>
#import "Live2DModelSetting.h"
#import "Motion/Live2DCubismMotion.h"

NS_ASSUME_NONNULL_BEGIN

@interface Live2DUserModel : NSObject

@property (nonatomic) Live2DModelSetting *setting;

/// 动作列表
@property (nonatomic, copy, readonly) NSDictionary<NSString *, Live2DCubismMotion *> *motions;
/// 表情列表
@property (nonatomic, copy, readonly) NSDictionary<NSString *, Live2DCubismMotion *> *expressions;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithHomeDir:(NSString *)homeDir fileName:(NSString *)fileName error:(NSError **)error NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
