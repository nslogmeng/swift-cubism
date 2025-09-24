//
//  Live2DCubismMotion+Internal.h
//  Cubism
//
//  Created by Meng on 2025/8/26.
//

#pragma once

#import <Foundation/Foundation.h>
#import "Live2DCubismMotion.h"
#import <Motion/ACubismMotion.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface Live2DCubismMotion(Internal)

@property (nonatomic, assign) Csm::ACubismMotion *motion;

- (instancetype)initWithName:(NSString *)name motion:(Csm::ACubismMotion *)motion;

@end

NS_ASSUME_NONNULL_END
