//
//  Live2DUserModel.m
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import "Live2DModelSetting+Internal.h"
#import "Live2DModelSetting.h"
#import "Live2DUserModel+Internal.h"
#import "Live2DUserModel.h"
#import "Motion/Live2DCubismMotion+Internal.h"
#import "Motion/Live2DCubismMotion.h"
#import "Platform/PlatformConfig.h"
#import "Platform/PlatformOption.h"
#import <CubismDefaultParameterId.hpp>
#import <CubismModelSettingJson.hpp>
#import <Effect/CubismBreath.hpp>
#import <Effect/CubismEyeBlink.hpp>
#import <Effect/CubismPose.hpp>
#import <Id/CubismIdManager.hpp>
#import <Motion/CubismMotion.hpp>
#import <Motion/CubismMotionQueueEntry.hpp>
#import <Physics/CubismPhysics.hpp>
#import <Rendering/Metal/CubismRenderer_Metal.hpp>
#import <Type/csmString.hpp>
#import <Utils/CubismString.hpp>
#import <Math/CubismMatrix44.hpp>

using namespace Live2D::Cubism::Framework;
using namespace Live2D::Cubism::Framework::DefaultParameterId;

@interface Live2DUserModel()

@property (nonatomic, readwrite) CGFloat opacity;
@property (nonatomic, readwrite) void *modelMatrix;

@property (nonatomic, assign) Live2D::Cubism::Live2DCubismUserModel *model;

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

@implementation Live2DUserModel

#pragma mark - Initialization

- (nullable instancetype)initWithHomeDir:(NSString *)homeDir
                                fileName:(NSString *)fileName
                                   error:(NSError **)error {
    self = [super init];
    if (self) {
        _userTimeSeconds = 0.0f;
        _internalDragX = 0.0f;
        _internalDragY = 0.0f;
        _internalOpacity = 1.0f;

        // 创建 UserModel 实例
        _model = new Live2D::Cubism::Live2DCubismUserModel();

        // 初始化参数ID
        _angleX = CubismFramework::GetIdManager()->GetId(ParamAngleX);
        _angleY = CubismFramework::GetIdManager()->GetId(ParamAngleY);
        _angleZ = CubismFramework::GetIdManager()->GetId(ParamAngleZ);
        _bodyAngleX = CubismFramework::GetIdManager()->GetId(ParamBodyAngleX);
        _eyeBallX = CubismFramework::GetIdManager()->GetId(ParamEyeBallX);
        _eyeBallY = CubismFramework::GetIdManager()->GetId(ParamEyeBallY);

        // 初始化设置
        _setting = [[Live2DModelSetting alloc] initWithHomeDir:homeDir fileName:fileName error:error];
        if ((error && *error) || !_setting) {
            [self cleanup];
            return nil;
        }

        // 加载模型资源
        [self loadAssetsWithError:error];
        if (error && *error) {
            [self cleanup];
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    [self cleanup];
}

- (void)cleanup {
    // 释放所有动作
    [self releaseMotions];
    [self releaseExpressions];

    // 释放动作组
    for (csmInt32 i = 0; i < self.setting.modelSetting->GetMotionGroupCount(); i++) {
        const csmChar* group = self.setting.modelSetting->GetMotionGroupName(i);
        [self releaseMotionGroup:group];
    }

    // 释放纹理
    [self releaseTextures];

    // 销毁渲染缓冲区
    _renderBuffer.DestroyOffscreenSurface();

    // 释放 UserModel
    if (_model) {
        delete _model;
        _model = nullptr;
    }
}

#pragma mark - Model Loading

- (void)loadAssetsWithError:(NSError **)error {
    if (_model == nullptr) {
        if (error) {
            *error = [NSError errorWithDomain:@"Live2DCubism" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"UserModel is not initialized"}];
        }
        return;
    }

    // 设置模型设置
    [self setupModelWithError:error];
    if (error && *error) {
        return;
    }

    // 创建渲染器
    _model->CreateRenderer();

    // 设置纹理
    [self setupTextures];
}

- (void)setupModelWithError:(NSError **)error {
    if (_model == nullptr || self.setting.modelSetting == nullptr) {
        return;
    }

    _model->SetUpdating(true);
    _model->SetInitialized(false);

    csmByte* buffer;
    csmSizeInt size;

    // Cubism模型
    if (strcmp(self.setting.modelSetting->GetModelFileName(), "") != 0) {
        csmString path = self.setting.modelSetting->GetModelFileName();
        path = csmString(_setting.homeDir.UTF8String) + path;

        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        _model->LoadModel(buffer, size);
        PlatformOption::ReleaseBytes(buffer);
    }

    // 表情
    if (self.setting.modelSetting->GetExpressionCount() > 0) {
        const csmInt32 count = self.setting.modelSetting->GetExpressionCount();
        for (csmInt32 i = 0; i < count; i++) {
            csmString name = self.setting.modelSetting->GetExpressionName(i);
            csmString path = self.setting.modelSetting->GetExpressionFileName(i);
            path = csmString(_setting.homeDir.UTF8String) + path;

            buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
            ACubismMotion* motion = _model->LoadExpression(buffer, size, name.GetRawString());

            if (motion) {
                if (_expressions[name] != NULL) {
                    ACubismMotion::Delete(_expressions[name]);
                    _expressions[name] = NULL;
                }
                _expressions[name] = motion;
            }

            PlatformOption::ReleaseBytes(buffer);
        }
    }

    // 物理
    if (strcmp(self.setting.modelSetting->GetPhysicsFileName(), "") != 0) {
        csmString path = self.setting.modelSetting->GetPhysicsFileName();
        path = csmString(_setting.homeDir.UTF8String) + path;

        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        _model->LoadPhysics(buffer, size);
        PlatformOption::ReleaseBytes(buffer);
    }

    // 姿势
    if (strcmp(self.setting.modelSetting->GetPoseFileName(), "") != 0) {
        csmString path = self.setting.modelSetting->GetPoseFileName();
        path = csmString(_setting.homeDir.UTF8String) + path;

        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        _model->LoadPose(buffer, size);
        PlatformOption::ReleaseBytes(buffer);
    }

    // 眨眼
    if (self.setting.modelSetting->GetEyeBlinkParameterCount() > 0) {
        // TODO
//        _model->_eyeBlink = CubismEyeBlink::Create(self.setting.modelSetting);
    }

    // 呼吸
    {
        _model->SetBreath(CubismBreath::Create());

        csmVector<CubismBreath::BreathParameterData> breathParameters;

        breathParameters.PushBack(CubismBreath::BreathParameterData(_angleX, 0.0f, 15.0f, 6.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_angleY, 0.0f, 8.0f, 3.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_angleZ, 0.0f, 10.0f, 5.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_bodyAngleX, 0.0f, 4.0f, 15.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(CubismFramework::GetIdManager()->GetId(ParamBreath), 0.5f, 0.5f, 3.2345f, 0.5f));

        _model->GetBreath()->SetParameters(breathParameters);
    }

    // 用户数据
    if (strcmp(self.setting.modelSetting->GetUserDataFile(), "") != 0) {
        csmString path = self.setting.modelSetting->GetUserDataFile();
        path = csmString(_setting.homeDir.UTF8String) + path;
        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        _model->LoadUserData(buffer, size);
        PlatformOption::ReleaseBytes(buffer);
    }

    // EyeBlinkIds
    {
        csmInt32 eyeBlinkIdCount = self.setting.modelSetting->GetEyeBlinkParameterCount();
        for (csmInt32 i = 0; i < eyeBlinkIdCount; ++i) {
            _eyeBlinkIds.PushBack(_setting.modelSetting->GetEyeBlinkParameterId(i));
        }
    }

    // LipSyncIds
    {
        csmInt32 lipSyncIdCount = self.setting.modelSetting->GetLipSyncParameterCount();
        for (csmInt32 i = 0; i < lipSyncIdCount; ++i) {
            _lipSyncIds.PushBack(_setting.modelSetting->GetLipSyncParameterId(i));
        }
    }

    // 布局
    csmMap<csmString, csmFloat32> layout;
    self.setting.modelSetting->GetLayoutMap(layout);
    _model->GetModelMatrix()->SetupFromLayout(layout);

    _model->GetModel()->SaveParameters();

    // 预加载动作
    for (csmInt32 i = 0; i < self.setting.modelSetting->GetMotionGroupCount(); i++) {
        const csmChar* group = self.setting.modelSetting->GetMotionGroupName(i);
        [self preloadMotionGroup:group];
    }

    _model->GetMotionManager()->StopAllMotions();

    _model->SetUpdating(false);
    _model->SetInitialized(true);
}

#pragma mark - Texture Management

- (void)setupTextures {
    auto renderer = _model->GetRenderer<Rendering::CubismRenderer_Metal>();
    if (!renderer) {
        return;
    }

    for (csmInt32 modelTextureNumber = 0; modelTextureNumber < self.setting.modelSetting->GetTextureCount(); modelTextureNumber++) {
        // 若纹理名为空字符串，则跳过加载和绑定处理
        if (!strcmp(self.setting.modelSetting->GetTextureFileName(modelTextureNumber), "")) {
            continue;
        }

        // 加载到Metal纹理
        csmString texturePath = self.setting.modelSetting->GetTextureFileName(modelTextureNumber);
        texturePath = csmString(_setting.homeDir.UTF8String) + texturePath;

        // TODO: 实现纹理加载逻辑
        // 这里需要从文件加载纹理并绑定到渲染器
        // 示例代码：
        // id<MTLTexture> metalTexture = [self.textureManager loadTextureFromFile:texturePath.GetRawString()];
        // if (metalTexture) {
        //     renderer->BindTexture(modelTextureNumber, metalTexture);
        // }

        // 临时：绑定空纹理以避免崩溃
        renderer->BindTexture(modelTextureNumber, nil);
    }

    // 设置预乘alpha
    renderer->IsPremultipliedAlpha(false);
}

- (void)releaseTextures {
    // TODO: 释放纹理资源
    // 这里需要调用纹理管理器来释放纹理
}

#pragma mark - Motion Management

- (void)preloadMotionGroup:(const csmChar*)group {
    const csmInt32 count = self.setting.modelSetting->GetMotionCount(group);

    for (csmInt32 i = 0; i < count; i++) {
        // 例如 idle_0
        csmString name = Utils::CubismString::GetFormatedString("%s_%d", group, i);
        csmString path = self.setting.modelSetting->GetMotionFileName(group, i);
        path = csmString(_setting.homeDir.UTF8String) + path;

        csmByte* buffer;
        csmSizeInt size;
        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        CubismMotion* tmpMotion = static_cast<CubismMotion*>(_model->LoadMotion(buffer, size, name.GetRawString(), NULL, NULL, self.setting.modelSetting, group, i));

        if (tmpMotion) {
            tmpMotion->SetEffectIds(_eyeBlinkIds, _lipSyncIds);

            if (_motions[name] != NULL) {
                ACubismMotion::Delete(_motions[name]);
            }
            _motions[name] = tmpMotion;
        }

        PlatformOption::ReleaseBytes(buffer);
    }
}

- (void)releaseMotionGroup:(const csmChar*)group {
    const csmInt32 count = self.setting.modelSetting->GetMotionCount(group);
    for (csmInt32 i = 0; i < count; i++) {
        csmString voice = self.setting.modelSetting->GetMotionSoundFileName(group, i);
        if (strcmp(voice.GetRawString(), "") != 0) {
            csmString path = voice;
            path = csmString(_setting.homeDir.UTF8String) + path;
            // TODO: 释放音频资源
        }
    }
}

- (void)releaseMotions {
    for (csmMap<csmString, ACubismMotion*>::const_iterator iter = _motions.Begin(); iter != _motions.End(); ++iter) {
        ACubismMotion::Delete(iter->Second);
    }
    _motions.Clear();
}

- (void)releaseExpressions {
    for (csmMap<csmString, ACubismMotion*>::const_iterator iter = _expressions.Begin(); iter != _expressions.End(); ++iter) {
        ACubismMotion::Delete(iter->Second);
    }
    _expressions.Clear();
}

#pragma mark - Public Interface

- (void)reloadRenderer {
    if (_model) {
        _model->DeleteRenderer();
        _model->CreateRenderer();
        [self setupTextures];
    }
}

- (void)update {
    if (_model == nullptr) {
        return;
    }

    CubismModel *model = _model->GetModel();
    CubismMotionManager *motionManager = _model->GetMotionManager();

    const csmFloat32 deltaTimeSeconds = 0.016f; // 假设60FPS
    _userTimeSeconds += deltaTimeSeconds;

    _model->GetDragManager()->Update(deltaTimeSeconds);
    _model->SetDragX(_internalDragX);
    _model->SetDragY(_internalDragY);

    // 通过动作更新参数的有无
    csmBool motionUpdated = false;

    //-----------------------------------------------------------------
    model->LoadParameters(); // 加载上次保存的状态
    if (motionManager->IsFinished()) {
        // 若没有动作播放，则从待机动作中随机播放一个
        [self startRandomMotionWithGroup:@"idle" priority:1 finishedHandler:nil beganHandler:nil];
    } else {
        motionUpdated = motionManager->UpdateMotion(model, deltaTimeSeconds); // 更新动作
    }
    model->SaveParameters(); // 保存状态
    //-----------------------------------------------------------------

    // 不透明度
    _internalOpacity = model->GetModelOpacity();

    // 眨眼
    if (!motionUpdated) {
        if (_model->GetEyeBlink() != NULL) {
            // 主动作未更新时
            _model->GetEyeBlink()->UpdateParameters(model, deltaTimeSeconds); // 眨眼
        }
    }

    if (_model->GetExpressionManager() != NULL) {
        _model->GetExpressionManager()->UpdateMotion(model, deltaTimeSeconds); // 通过表情更新参数（相对变化）
    }

    // 拖拽变化
    // 通过拖拽调整脸部朝向
    model->AddParameterValue(_angleX, _internalDragX * 30); // 添加-30到30的值
    model->AddParameterValue(_angleY, _internalDragY * 30);
    model->AddParameterValue(_angleZ, _internalDragX * _internalDragY * -30);

    // 通过拖拽调整身体朝向
    model->AddParameterValue(_bodyAngleX, _internalDragX * 10); // 添加-10到10的值

    // 通过拖拽调整眼睛朝向
    model->AddParameterValue(_eyeBallX, _internalDragX); // 添加-1到1的值
    model->AddParameterValue(_eyeBallY, _internalDragY);

    // 呼吸等
    if (_model->GetBreath() != NULL) {
        _model->GetBreath()->UpdateParameters(model, deltaTimeSeconds);
    }

    // 物理运算设置
    if (_model->GetPhysics() != NULL) {
        _model->GetPhysics()->Evaluate(model, deltaTimeSeconds);
    }

    // 唇形同步设置
    if (_model->GetLipSync()) {
        csmFloat32 value = 0; // 若实时唇形同步，从系统获取音量并输入0~1范围的值

        for (csmUint32 i = 0; i < _lipSyncIds.GetSize(); ++i) {
            model->AddParameterValue(_lipSyncIds[i], value, 0.8f);
        }
    }

    // 姿势设置
    if (_model->GetPose() != NULL) {
        _model->GetPose()->UpdateParameters(model, deltaTimeSeconds);
    }

    model->Update();
}

- (void)drawWithMatrix:(float[16])matrix {
    if (_model == nullptr) {
        return;
    }

    CubismMatrix44 cubismMatrix;
    cubismMatrix.SetMatrix(matrix);

    // TODO: check
    cubismMatrix.MultiplyByMatrix(_model->GetModelMatrix());

    auto renderer = _model->GetRenderer<Rendering::CubismRenderer_Metal>();
    if (renderer) {
        renderer->SetMvpMatrix(&cubismMatrix);
        renderer->DrawModel();
    }
}

- (NSInteger)startMotionWithGroup:(NSString *)group
                            index:(NSInteger)index
                         priority:(NSInteger)priority
                  finishedHandler:(Live2DCubismMotionFinishedCallback)finishedHandler
                     beganHandler:(Live2DCubismMotionBeganCallback)beganHandler {
    if (_model == nullptr) {
        return -1;
    }

    if (priority == 1) {
        _model->GetMotionManager()->SetReservePriority((csmInt32)priority);
    } else if (!_model->GetMotionManager()->ReserveMotion((csmInt32)priority)) {
        return -1;
    }

    const csmString fileName = self.setting.modelSetting->GetMotionFileName([group cStringUsingEncoding:NSUTF8StringEncoding], (csmInt32)index);

    // 例如 idle_0
    csmString name = Utils::CubismString::GetFormatedString("%s_%d", [group cStringUsingEncoding:NSUTF8StringEncoding], (csmInt32)index);
    CubismMotion* motion = static_cast<CubismMotion*>(_motions[name.GetRawString()]);
    csmBool autoDelete = false;

    if (motion == NULL) {
        csmString path = fileName;
        path = csmString(_setting.homeDir.UTF8String) + path;

        csmByte* buffer;
        csmSizeInt size;
        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        motion = static_cast<CubismMotion*>(_model->LoadMotion(buffer, size, NULL, NULL, NULL, self.setting.modelSetting, [group cStringUsingEncoding:NSUTF8StringEncoding], (csmInt32)index));

        if (motion) {
            motion->SetEffectIds(_eyeBlinkIds, _lipSyncIds);
            autoDelete = true; // 終了時にメモリから削除
        }

        PlatformOption::ReleaseBytes(buffer);
    } else {
        // 设置回调
        if (beganHandler) {
            // TODO: 设置 began 回调
        }
        if (finishedHandler) {
            // TODO: 设置 finished 回调
        }
    }

    // TODO: 处理声音文件

    return (NSInteger)_model->GetMotionManager()->StartMotionPriority(motion, autoDelete, (csmInt32)priority);
}

- (NSInteger)startRandomMotionWithGroup:(NSString *)group
                               priority:(NSInteger)priority
                        finishedHandler:(Live2DCubismMotionFinishedCallback)finishedHandler
                          beganHandler:(Live2DCubismMotionBeganCallback)beganHandler {
    if (self.setting.modelSetting->GetMotionCount([group cStringUsingEncoding:NSUTF8StringEncoding]) == 0) {
        return -1;
    }

    csmInt32 no = rand() % self.setting.modelSetting->GetMotionCount([group cStringUsingEncoding:NSUTF8StringEncoding]);

    return [self startMotionWithGroup:group index:no priority:priority finishedHandler:finishedHandler beganHandler:beganHandler];
}

- (void)setExpression:(NSString *)expressionID {
    ACubismMotion* motion = _expressions[[expressionID cStringUsingEncoding:NSUTF8StringEncoding]];
    if (motion != NULL) {
        _model->GetExpressionManager()->StartMotion(motion, false);
    }
}

- (void)setRandomExpression {
    if (_expressions.GetSize() == 0) {
        return;
    }

    csmInt32 no = rand() % _expressions.GetSize();
    csmMap<csmString, ACubismMotion*>::const_iterator map_ite;
    csmInt32 i = 0;
    for (map_ite = _expressions.Begin(); map_ite != _expressions.End(); map_ite++) {
        if (i == no) {
            csmString name = (*map_ite).First;
            [self setExpression:[NSString stringWithUTF8String:name.GetRawString()]];
            return;
        }
        i++;
    }
}

- (BOOL)hitTestWithHitAreaName:(NSString *)hitAreaName x:(CGFloat)x y:(CGFloat)y {
    // 若透明则无判定
    if (_internalOpacity < 1) {
        return false;
    }
    const csmInt32 count = self.setting.modelSetting->GetHitAreasCount();
    for (csmInt32 i = 0; i < count; i++) {
        if (strcmp(self.setting.modelSetting->GetHitAreaName(i), [hitAreaName cStringUsingEncoding:NSUTF8StringEncoding]) == 0) {
            const CubismIdHandle drawID = self.setting.modelSetting->GetHitAreaId(i);
            return _model->IsHit(drawID, (csmFloat32)x, (csmFloat32)y);
        }
    }
    return false; // 若不存在则返回false
}

- (BOOL)hasMocConsistencyFromFile:(NSString *)mocFileName {
    csmString path = [mocFileName cStringUsingEncoding:NSUTF8StringEncoding];
    path = csmString(_setting.homeDir.UTF8String) + path;

    csmByte* buffer;
    csmSizeInt size;

    buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);

    csmBool consistency = CubismMoc::HasMocConsistencyFromUnrevivedMoc(buffer, size);

    PlatformOption::ReleaseBytes(buffer);

    return consistency ? YES : NO;
}

- (void)motionEventFired:(NSString *)eventValue {
    CubismLogInfo("%s is fired on Live2DUserModel!!", [eventValue cStringUsingEncoding:NSUTF8StringEncoding]);
}

#pragma mark - Property Accessors

- (CGFloat)opacity {
    return _internalOpacity;
}

- (void)setDragX:(CGFloat)dragX {
    _internalDragX = dragX;
}

- (void)setDragY:(CGFloat)dragY {
    _internalDragY = dragY;
}

- (CGFloat)dragX {
    return _internalDragX;
}

- (CGFloat)dragY {
    return _internalDragY;
}

- (void *)modelMatrix {
    return _model ? _model->GetModelMatrix() : nullptr;
}

@end
