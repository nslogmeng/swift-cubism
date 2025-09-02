//
//  Live2DTexture.h
//  Cubism
//
//  Created by Meng on 2025/9/2.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/// Live2D 纹理信息
@interface Live2DTexture : NSObject

/// 真实加载的纹理数据
@property (nonatomic, readonly) id<MTLTexture> texture;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithTextureFilePath:(NSString *)filePath error:(NSError **)error NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
