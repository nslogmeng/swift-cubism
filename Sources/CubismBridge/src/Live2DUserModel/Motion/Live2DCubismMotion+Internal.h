//
//  Live2DCubismMotion+Internal.h
//  Cubism
//
//  Created by Meng on 2025/8/26.
//

#import <Foundation/Foundation.h>
#import "Live2DCubismMotion.h"
#import <Motion/ACubismMotion.hpp>

using namespace Csm;

NS_ASSUME_NONNULL_BEGIN

@interface Live2DCubismMotion(Internal)

@property (nonatomic, assign) ACubismMotion *motion;

- (instancetype)initWithName:(NSString *)name motion:(ACubismMotion *)motion;

@end

NS_ASSUME_NONNULL_END
