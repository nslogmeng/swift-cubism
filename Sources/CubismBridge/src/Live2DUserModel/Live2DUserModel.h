//
//  Live2DUserModel.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import <Foundation/Foundation.h>
#import "Live2DModelSetting.h"

NS_ASSUME_NONNULL_BEGIN

/// 动作播放完成回调
typedef void (^Live2DCubismMotionFinishedCallback)(NSString *motionGroup, NSInteger motionIndex);
/// 动作播放开始回调
typedef void (^Live2DCubismMotionBeganCallback)(NSString *motionGroup, NSInteger motionIndex);

@interface Live2DUserModel : NSObject

@property (nonatomic, readonly) Live2DModelSetting *setting;

/// 模型不透明度
@property (nonatomic, readonly) CGFloat opacity;

/// 拖拽位置X
@property (nonatomic) CGFloat dragX;
/// 拖拽位置Y
@property (nonatomic) CGFloat dragY;

/// 模型矩阵
@property (nonatomic, readonly) void *modelMatrix;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithHomeDir:(NSString *)homeDir error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/// 重新构建渲染器
- (void)reloadRenderer;

/// 更新模型。根据模型参数决定绘制状态
- (void)update;

/// 绘制模型。传递模型绘制空间的 View-Projection 矩阵
/// @param matrix View-Projection矩阵 (4x4 浮点数组)
// TODO:
//- (void)drawWithMatrix:(float[16])matrix;

/// 开始播放指定参数的动作
/// @param group 动作组名
/// @param index 组内编号
/// @param priority 优先级
/// @param finishedHandler 动作播放结束时回调
/// @param beganHandler 动作播放开始时回调
/// @return 返回开始的动作标识号，失败时返回-1
- (NSInteger)startMotionWithGroup:(NSString *)group
                            index:(NSInteger)index
                         priority:(NSInteger)priority
                  finishedHandler:(nullable Live2DCubismMotionFinishedCallback)finishedHandler
                     beganHandler:(nullable Live2DCubismMotionBeganCallback)beganHandler;

/// 随机选择动作并开始播放
/// @param group 动作组名
/// @param priority 优先级
/// @param finishedHandler 动作播放结束时回调
/// @param beganHandler 动作播放开始时回调
/// @return 返回开始的动作标识号，失败时返回-1
- (NSInteger)startRandomMotionWithGroup:(NSString *)group
                               priority:(NSInteger)priority
                        finishedHandler:(nullable Live2DCubismMotionFinishedCallback)finishedHandler
                           beganHandler:(nullable Live2DCubismMotionBeganCallback)beganHandler;

/// 设置指定参数的表情动作
/// @param expressionID 表情动作ID
- (void)setExpression:(NSString *)expressionID;

/// 随机设置表情动作
- (void)setRandomExpression;

/// 碰撞判定测试。从指定ID的顶点列表计算矩形，判断坐标是否在矩形范围内
/// @param hitAreaName 要测试碰撞判定的目标ID
/// @param x 要判定的X坐标
/// @param y 要判定的Y坐标
/// @return 是否碰撞
- (BOOL)hitTestWithHitAreaName:(NSString *)hitAreaName x:(CGFloat)x y:(CGFloat)y;

/// 检查 .moc3 文件的完整性
/// @param mocFileName MOC3文件名
/// @return 若MOC3完整则返回YES，否则返回NO
- (BOOL)hasMocConsistencyFromFile:(NSString *)mocFileName;

/// 接收事件触发
/// @param eventValue 事件值
- (void)motionEventFired:(NSString *)eventValue;

@end

NS_ASSUME_NONNULL_END
