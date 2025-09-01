//
//  Live2DUserModel+Internal.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import "Live2DUserModel.h"
#import "Live2DCubismUserModel.h"
#import <Foundation/Foundation.h>
#import <ICubismModelSetting.hpp>
#import <Type/csmRectF.hpp>
#import <Rendering/Metal/CubismOffscreenSurface_Metal.hpp>
#import <Model/CubismUserModel.hpp>
#import <CubismDefaultParameterId.hpp>
#import <Motion/ACubismMotion.hpp>
#import <Effect/CubismEyeBlink.hpp>
#import <Effect/CubismBreath.hpp>
#import <Physics/CubismPhysics.hpp>
#import <Motion/CubismMotionManager.hpp>
#import <Motion/CubismExpressionMotionManager.hpp>

NS_ASSUME_NONNULL_BEGIN

using namespace Live2D::Cubism::Framework;
using namespace Live2D::Cubism::Framework::DefaultParameterId;

@interface Live2DUserModel(Internal)

@property (nonatomic, assign) Live2D::Cubism::Live2DCubismUserModel *model;

/// 模型根目录
@property (nonatomic, copy) NSString *modelHomeDir;
/// 累计的时间差值[秒]
@property (nonatomic) CGFloat userTimeSeconds;

/// 眨眼参数
@property (nonatomic, assign) Csm::csmVector<Csm::CubismIdHandle> eyeBlinkIds;
/// 口型同步参数
@property (nonatomic, assign) Csm::csmVector<Csm::CubismIdHandle> lipSyncIds;

/// 碰撞区域
@property (nonatomic, assign) Csm::csmVector<Csm::csmRectF> hitArea;
/// 用户区域
@property (nonatomic, assign) Csm::csmVector<Csm::csmRectF> userArea;

/// 参数ID
@property (nonatomic, assign) const Csm::CubismId *angleX;
@property (nonatomic, assign) const Csm::CubismId *angleY;
@property (nonatomic, assign) const Csm::CubismId *angleZ;
@property (nonatomic, assign) const Csm::CubismId *bodyAngleX;
@property (nonatomic, assign) const Csm::CubismId *eyeBallX;
@property (nonatomic, assign) const Csm::CubismId *eyeBallY;

/// 渲染缓冲区
@property (nonatomic, assign) Rendering::CubismOffscreenSurface_Metal renderBuffer;

/// 内部动作列表 (C++ map)
@property (nonatomic, assign) Csm::csmMap<Csm::csmString, Csm::ACubismMotion*> motions;
/// 内部表情列表 (C++ map)
@property (nonatomic, assign) Csm::csmMap<Csm::csmString, Csm::ACubismMotion*> expressions;

/// 拖拽位置 (内部使用)
@property (nonatomic) CGFloat internalDragX;
@property (nonatomic) CGFloat internalDragY;

/// 模型不透明度 (内部使用)
@property (nonatomic) CGFloat internalOpacity;

/// 纹理管理器 (平台相关，需要外部注入)
@property (nonatomic, weak, nullable) id textureManager;

@end

NS_ASSUME_NONNULL_END
