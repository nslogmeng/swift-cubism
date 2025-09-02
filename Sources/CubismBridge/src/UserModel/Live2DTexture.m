//
//  Live2DTexture.m
//  Cubism
//
//  Created by Meng on 2025/9/2.
//

#import "Live2DTexture.h"
#import <Platform/PlatformConfig.h>
#import <Platform/PlatformError.h>
#import <UIKit/UIKit.h>

@interface Live2DTexture()

@property (nonatomic, copy) NSString *filePath;

/// 真实加载的纹理数据
@property (nonatomic, readwrite) id<MTLTexture> texture;

// image infos
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger bytesPerRow;
@property (nonatomic, assign) NSInteger byteCount;

@end

@implementation Live2DTexture

- (nullable instancetype)initWithTextureFilePath:(NSString *)filePath error:(NSError **)error {
    self = [super init];
    if (self) {
        _filePath = filePath;
        _texture = [self loadTextureWithError:error];

        if (!_texture || (error && *error)) {
            return nil;
        }
    }
    return self;
}

- (id<MTLTexture>)loadTextureWithError:(NSError **)error {
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:_filePath];
    CGImageRef cgImage = [image CGImage];
    if (!image || !cgImage) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeLoadTextureFailed];
        }
        return nil;
    }

    _width = CGImageGetWidth(cgImage);
    _height = CGImageGetHeight(cgImage);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint32_t bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;

    _bytesPerRow = _width * 4;
    _byteCount = _bytesPerRow * _height;

    CGContextRef context = CGBitmapContextCreate(NULL, _width, _height, 8, _bytesPerRow, colorSpace, bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    if (!context) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeLoadTextureFailed];
        }
        return nil;
    }

    CGRect rect = CGRectMake(0.0, 0.0, _width, _height);
    CGContextDrawImage(context, rect, cgImage);
    void *data = CGBitmapContextGetData(context);
    if (!data) {
        CGContextRelease(context);
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeLoadTextureFailed];
        }
        return nil;
    }

    id<MTLTexture> texture = [self buildTextureWithData:data error:error];
    CGContextRelease(context);
    return texture;
}

- (id<MTLTexture>)buildTextureWithData:(void *)data error:(NSError **)error {
    // 每个像素有 RGBA 通道，每个通道都是 8 位无符号归一化值（即 0 映射为 0.0，255 映射为 1.0）
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                 width:_width
                                                                                                height:_height
                                                                                             mipmapped:YES];
    NSUInteger widthLevels = ceil(log2(_width));
    NSUInteger heightLevels = ceil(log2(_height));
    textureDescriptor.mipmapLevelCount = MAX(widthLevels, heightLevels);

    id<MTLTexture> texture = [PlatformConfig.MTLDevice newTextureWithDescriptor:textureDescriptor];
    if (!texture) {
        if (error) {
            *error = [PlatformError errorWithCode:CubismErrorCodeLoadTextureFailed];
        }
        return nil;
    }

    MTLRegion region = MTLRegionMake3D(0, 0, 0, _width, _height, 1);
    [texture replaceRegion:region mipmapLevel:0 withBytes:data bytesPerRow:_bytesPerRow];

    return texture;
}

@end
