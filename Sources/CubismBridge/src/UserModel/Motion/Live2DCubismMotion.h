//
//  Live2DCubismMotion.h
//  Cubism
//
//  Created by Meng on 2025/8/26.
//

#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Live2DCubismMotion : NSObject

/// Motion 名称
@property (nonatomic, copy, readonly) NSString *name;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
