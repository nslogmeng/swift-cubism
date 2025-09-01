//
//  CubismID.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import <Foundation/Foundation.h>
#import <Id/CubismId.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface CubismID(Internal)

@property (nonatomic, assign, readonly) Csm::CubismId *cubismID;

- (instancetype)initWithCubismID:(Csm::CubismId *)cubismID;

@end

NS_ASSUME_NONNULL_END
