//
//  Live2DUserModel.h
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import <Foundation/Foundation.h>
#import <ICubismModelSetting.hpp>
#import <Type/csmRectF.hpp>
#import <Rendering/Metal/CubismOffscreenSurface_Metal.hpp>
#import <Model/CubismUserModel.hpp>
#import <CubismDefaultParameterId.hpp>

NS_ASSUME_NONNULL_BEGIN

using namespace Live2D::Cubism::Framework;
using namespace Live2D::Cubism::Framework::DefaultParameterId;

@interface Live2DUserModel(Internal)

@property (nonatomic, assign) CubismUserModel *userModel;

/// 眨眼参数
@property (nonatomic, assign) Csm::csmVector<Csm::CubismIdHandle> eyeBlinkIds;
/// 口型同步参数
@property (nonatomic, assign) Csm::csmVector<Csm::CubismIdHandle> lipSyncIds;

@property (nonatomic, assign) Csm::csmVector<Csm::csmRectF> hitArea;
@property (nonatomic, assign) Csm::csmVector<Csm::csmRectF> userArea;

@property (nonatomic, assign) const Csm::CubismId *angleX;
@property (nonatomic, assign) const Csm::CubismId *angleY;
@property (nonatomic, assign) const Csm::CubismId *angleZ;
@property (nonatomic, assign) const Csm::CubismId *bodyAngleX;
@property (nonatomic, assign) const Csm::CubismId *eyeBallX;
@property (nonatomic, assign) const Csm::CubismId *eyeBallY;

@property (nonatomic, assign) Live2D::Cubism::Framework::Rendering::CubismOffscreenSurface_Metal renderBuffer;

@end

NS_ASSUME_NONNULL_END
