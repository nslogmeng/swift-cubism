//
//  Live2DModelSetting.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Live2DModelSetting: NSObject

/// 模型根目录
@property (nonatomic, copy, readonly) NSString *homeDir;
/// 模型配置文件名
@property (nonatomic, copy, readonly) NSString *fileName;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithHomeDir:(NSString *)homeDir fileName:(NSString *)fileName error:(NSError **)error NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
