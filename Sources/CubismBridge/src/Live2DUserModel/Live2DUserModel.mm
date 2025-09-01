//
//  Live2DUserModel.m
//  Cubism
//
//  Created by Meng on 2025/8/30.
//

#import "Live2DUserModel.h"
#import "Live2DUserModel+Internal.h"
#import "Live2DModelSetting.h"
#import "Live2DModelSetting+Internal.h"
#import "Platform/PlatformConfig.h"
#import "Platform/PlatformOption.h"
#import "Motion/Live2DCubismMotion.h"
#import "Motion/Live2DCubismMotion+Internal.h"
#import <Id/CubismIdManager.hpp>
#import <CubismDefaultParameterId.hpp>
#import <CubismModelSettingJson.hpp>
#import <Type/csmString.hpp>
#import <Utils/CubismString.hpp>
#import <Motion/CubismMotion.hpp>
#import <Motion/CubismMotionQueueEntry.hpp>
#import <Effect/CubismEyeBlink.hpp>
#import <Effect/CubismBreath.hpp>
#import <Effect/CubismPose.hpp>
#import <Physics/CubismPhysics.hpp>
#import <Rendering/Metal/CubismRenderer_Metal.hpp>

@interface Live2DUserModel()

@property (nonatomic, copy, readwrite) NSDictionary<NSString *, Live2DCubismMotion *> *motions;
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, Live2DCubismMotion *> *expressions;
@property (nonatomic, readwrite) CGFloat opacity;
@property (nonatomic, readwrite) void *modelMatrix;

@end

@implementation Live2DUserModel

#pragma mark - Initialization

- (nullable instancetype)initWithHomeDir:(NSString *)homeDir fileName:(NSString *)fileName error:(NSError **)error {
    self = [super init];
    if (self) {
        _modelHomeDir = [homeDir copy];
        _userTimeSeconds = 0.0f;
        _internalDragX = 0.0f;
        _internalDragY = 0.0f;
        _internalOpacity = 1.0f;

        // 创建 UserModel 实例
        _userModel = new CubismUserModel();

        // 初始化参数ID
        _angleX = CubismFramework::GetIdManager()->GetId(ParamAngleX);
        _angleY = CubismFramework::GetIdManager()->GetId(ParamAngleY);
        _angleZ = CubismFramework::GetIdManager()->GetId(ParamAngleZ);
        _bodyAngleX = CubismFramework::GetIdManager()->GetId(ParamBodyAngleX);
        _eyeBallX = CubismFramework::GetIdManager()->GetId(ParamEyeBallX);
        _eyeBallY = CubismFramework::GetIdManager()->GetId(ParamEyeBallY);

        // 初始化设置
        self.setting = [[Live2DModelSetting alloc] initWithHomeDir:homeDir fileName:fileName error:error];
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
    if (_userModel) {
        delete _userModel;
        _userModel = nullptr;
    }
}

#pragma mark - Model Loading

- (void)loadAssetsWithError:(NSError **)error {
    if (_userModel == nullptr) {
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
    _userModel->CreateRenderer();

    // 设置纹理
    [self setupTextures];
}

- (void)setupModelWithError:(NSError **)error {
    if (_userModel == nullptr || self.setting.modelSetting == nullptr) {
        return;
    }

    _userModel->_updating = true;
    _userModel->_initialized = false;

    csmByte* buffer;
    csmSizeInt size;

    // Cubism模型
    if (strcmp(self.setting.modelSetting->GetModelFileName(), "") != 0) {
        _setting.homeDir.UTF8String
        csmString path = self.setting.modelSetting->GetModelFileName();
        path = csmString(_modelHomeDir.UTF8String) + path;

        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        _userModel->LoadModel(buffer, size);
        PlatformOption::ReleaseBytes(buffer);
    }

    // 表情
    if (self.setting.modelSetting->GetExpressionCount() > 0) {
        const csmInt32 count = self.setting.modelSetting->GetExpressionCount();
        for (csmInt32 i = 0; i < count; i++) {
            csmString name = self.setting.modelSetting->GetExpressionName(i);
            csmString path = self.setting.modelSetting->GetExpressionFileName(i);
            path = csmString(_modelHomeDir.UTF8String) + path;

            buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
            ACubismMotion* motion = _userModel->LoadExpression(buffer, size, name.GetRawString());

            if (motion) {
                if (_internalExpressions[name] != NULL) {
                    ACubismMotion::Delete(_internalExpressions[name]);
                    _internalExpressions[name] = NULL;
                }
                _internalExpressions[name] = motion;
            }

            PlatformOption::ReleaseBytes(buffer);
        }
    }

    // 物理
    if (strcmp(self.setting.modelSetting->GetPhysicsFileName(), "") != 0) {
        csmString path = self.setting.modelSetting->GetPhysicsFileName();
        path = csmString(_modelHomeDir.UTF8String) + path;

        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        _userModel->LoadPhysics(buffer, size);
        PlatformOption::ReleaseBytes(buffer);
    }

    // 姿势
    if (strcmp(self.setting.modelSetting->GetPoseFileName(), "") != 0) {
        csmString path = self.setting.modelSetting->GetPoseFileName();
        path = csmString(_modelHomeDir.UTF8String) + path;

        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        _userModel->LoadPose(buffer, size);
        PlatformOption::ReleaseBytes(buffer);
    }

    // 眨眼
    if (self.setting.modelSetting->GetEyeBlinkParameterCount() > 0) {
        _userModel->_eyeBlink = CubismEyeBlink::Create(self.setting.modelSetting);
    }

    // 呼吸
    {
        _userModel->_breath = CubismBreath::Create();

        csmVector<CubismBreath::BreathParameterData> breathParameters;

        breathParameters.PushBack(CubismBreath::BreathParameterData(_angleX, 0.0f, 15.0f, 6.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_angleY, 0.0f, 8.0f, 3.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_angleZ, 0.0f, 10.0f, 5.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_bodyAngleX, 0.0f, 4.0f, 15.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(CubismFramework::GetIdManager()->GetId(ParamBreath), 0.5f, 0.5f, 3.2345f, 0.5f));

        _userModel->_breath->SetParameters(breathParameters);
    }

    // 用户数据
    if (strcmp(self.setting.modelSetting->GetUserDataFile(), "") != 0) {
        csmString path = self.setting.modelSetting->GetUserDataFile();
        path = csmString(_modelHomeDir.UTF8String) + path;
        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        _userModel->LoadUserData(buffer, size);
        PlatformOption::ReleaseBytes(buffer);
    }

    // EyeBlinkIds
    {
        csmInt32 eyeBlinkIdCount = self.setting.modelSetting->GetEyeBlinkParameterCount();
        for (csmInt32 i = 0; i < eyeBlinkIdCount; ++i) {
            _eyeBlinkIds.PushBack(self.setting.modelSetting->GetEyeBlinkParameterId(i));
        }
    }

    // LipSyncIds
    {
        csmInt32 lipSyncIdCount = self.setting.modelSetting->GetLipSyncParameterCount();
        for (csmInt32 i = 0; i < lipSyncIdCount; ++i) {
            _lipSyncIds.PushBack(self.setting.modelSetting->GetLipSyncParameterId(i));
        }
    }

    // 布局
    csmMap<csmString, csmFloat32> layout;
    self.setting.modelSetting->GetLayoutMap(layout);
    _userModel->_modelMatrix->SetupFromLayout(layout);

    _userModel->_model->SaveParameters();

    // 预加载动作
    for (csmInt32 i = 0; i < self.setting.modelSetting->GetMotionGroupCount(); i++) {
        const csmChar* group = self.setting.modelSetting->GetMotionGroupName(i);
        [self preloadMotionGroup:group];
    }

    _userModel->_motionManager->StopAllMotions();

    _userModel->_updating = false;
    _userModel->_initialized = true;
}

#pragma mark - Texture Management

- (void)setupTextures {
    auto renderer = _userModel->GetRenderer<Rendering::CubismRenderer_Metal>();
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
        texturePath = csmString(_modelHomeDir.UTF8String) + texturePath;

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
        path = csmString(_modelHomeDir.UTF8String) + path;

        csmByte* buffer;
        csmSizeInt size;
        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        CubismMotion* tmpMotion = static_cast<CubismMotion*>(_userModel->LoadMotion(buffer, size, name.GetRawString(), NULL, NULL, self.setting.modelSetting, group, i));

        if (tmpMotion) {
            tmpMotion->SetEffectIds(_eyeBlinkIds, _lipSyncIds);

            if (_internalMotions[name] != NULL) {
                ACubismMotion::Delete(_internalMotions[name]);
            }
            _internalMotions[name] = tmpMotion;
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
            path = csmString(_modelHomeDir.UTF8String) + path;
            // TODO: 释放音频资源
        }
    }
}

- (void)releaseMotions {
    for (csmMap<csmString, ACubismMotion*>::const_iterator iter = _internalMotions.Begin(); iter != _internalMotions.End(); ++iter) {
        ACubismMotion::Delete(iter->Second);
    }
    _internalMotions.Clear();
}

- (void)releaseExpressions {
    for (csmMap<csmString, ACubismMotion*>::const_iterator iter = _internalExpressions.Begin(); iter != _internalExpressions.End(); ++iter) {
        ACubismMotion::Delete(iter->Second);
    }
    _internalExpressions.Clear();
}

#pragma mark - Public Interface

- (void)reloadRenderer {
    if (_userModel) {
        _userModel->DeleteRenderer();
        _userModel->CreateRenderer();
        [self setupTextures];
    }
}

- (void)update {
    if (_userModel == nullptr) {
        return;
    }

    const csmFloat32 deltaTimeSeconds = 0.016f; // 假设60FPS
    _userTimeSeconds += deltaTimeSeconds;

    _userModel->_dragManager->Update(deltaTimeSeconds);
    _userModel->_dragX = _internalDragX;
    _userModel->_dragY = _internalDragY;

    // 通过动作更新参数的有无
    csmBool motionUpdated = false;

    //-----------------------------------------------------------------
    _userModel->_model->LoadParameters(); // 加载上次保存的状态
    if (_userModel->_motionManager->IsFinished()) {
        // 若没有动作播放，则从待机动作中随机播放一个
        [self startRandomMotionWithGroup:@"idle" priority:1 finishedHandler:nil beganHandler:nil];
    } else {
        motionUpdated = _userModel->_motionManager->UpdateMotion(_userModel->_model, deltaTimeSeconds); // 更新动作
    }
    _userModel->_model->SaveParameters(); // 保存状态
    //-----------------------------------------------------------------

    // 不透明度
    _internalOpacity = _userModel->_model->GetModelOpacity();

    // 眨眼
    if (!motionUpdated) {
        if (_userModel->_eyeBlink != NULL) {
            // 主动作未更新时
            _userModel->_eyeBlink->UpdateParameters(_userModel->_model, deltaTimeSeconds); // 眨眼
        }
    }

    if (_userModel->_expressionManager != NULL) {
        _userModel->_expressionManager->UpdateMotion(_userModel->_model, deltaTimeSeconds); // 通过表情更新参数（相对变化）
    }

    // 拖拽变化
    // 通过拖拽调整脸部朝向
    _userModel->_model->AddParameterValue(_angleX, _internalDragX * 30); // 添加-30到30的值
    _userModel->_model->AddParameterValue(_angleY, _internalDragY * 30);
    _userModel->_model->AddParameterValue(_angleZ, _internalDragX * _internalDragY * -30);

    // 通过拖拽调整身体朝向
    _userModel->_model->AddParameterValue(_bodyAngleX, _internalDragX * 10); // 添加-10到10的值

    // 通过拖拽调整眼睛朝向
    _userModel->_model->AddParameterValue(_eyeBallX, _internalDragX); // 添加-1到1的值
    _userModel->_model->AddParameterValue(_eyeBallY, _internalDragY);

    // 呼吸等
    if (_userModel->_breath != NULL) {
        _userModel->_breath->UpdateParameters(_userModel->_model, deltaTimeSeconds);
    }

    // 物理运算设置
    if (_userModel->_physics != NULL) {
        _userModel->_physics->Evaluate(_userModel->_model, deltaTimeSeconds);
    }

    // 唇形同步设置
    if (_userModel->_lipSync) {
        csmFloat32 value = 0; // 若实时唇形同步，从系统获取音量并输入0~1范围的值

        for (csmUint32 i = 0; i < _lipSyncIds.GetSize(); ++i) {
            _userModel->_model->AddParameterValue(_lipSyncIds[i], value, 0.8f);
        }
    }

    // 姿势设置
    if (_userModel->_pose != NULL) {
        _userModel->_pose->UpdateParameters(_userModel->_model, deltaTimeSeconds);
    }

    _userModel->_model->Update();
}

- (void)drawWithMatrix:(float[16])matrix {
    if (_userModel == nullptr) {
        return;
    }

    CubismMatrix44 cubismMatrix;
    cubismMatrix.SetMatrix(matrix);

    cubismMatrix.MultiplyByMatrix(*_userModel->_modelMatrix);

    auto renderer = _userModel->GetRenderer<Rendering::CubismRenderer_Metal>();
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
    if (_userModel == nullptr) {
        return -1;
    }

    if (priority == 1) {
        _userModel->_motionManager->SetReservePriority(priority);
    } else if (!_userModel->_motionManager->ReserveMotion(priority)) {
        return -1;
    }

    const csmString fileName = self.setting.modelSetting->GetMotionFileName([group cStringUsingEncoding:NSUTF8StringEncoding], (csmInt32)index);

    // 例如 idle_0
    csmString name = Utils::CubismString::GetFormatedString("%s_%d", [group cStringUsingEncoding:NSUTF8StringEncoding], (csmInt32)index);
    CubismMotion* motion = static_cast<CubismMotion*>(_internalMotions[name.GetRawString()]);
    csmBool autoDelete = false;

    if (motion == NULL) {
        csmString path = fileName;
        path = csmString(_modelHomeDir.UTF8String) + path;

        csmByte* buffer;
        csmSizeInt size;
        buffer = PlatformOption::LoadFileAsBytes(path.GetRawString(), &size);
        motion = static_cast<CubismMotion*>(_userModel->LoadMotion(buffer, size, NULL, NULL, NULL, self.setting.modelSetting, [group cStringUsingEncoding:NSUTF8StringEncoding], (csmInt32)index));

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

    return (NSInteger)_userModel->_motionManager->StartMotionPriority(motion, autoDelete, priority);
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
    ACubismMotion* motion = _internalExpressions[[expressionID cStringUsingEncoding:NSUTF8StringEncoding]];
    if (motion != NULL) {
        _userModel->_expressionManager->StartMotion(motion, false);
    }
}

- (void)setRandomExpression {
    if (_internalExpressions.GetSize() == 0) {
        return;
    }

    csmInt32 no = rand() % _internalExpressions.GetSize();
    csmMap<csmString, ACubismMotion*>::const_iterator map_ite;
    csmInt32 i = 0;
    for (map_ite = _internalExpressions.Begin(); map_ite != _internalExpressions.End(); map_ite++) {
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
            return _userModel->IsHit(drawID, (csmFloat32)x, (csmFloat32)y);
        }
    }
    return false; // 若不存在则返回false
}

- (void *)renderBuffer {
    return &_renderBuffer;
}

- (BOOL)hasMocConsistencyFromFile:(NSString *)mocFileName {
    csmString path = [mocFileName cStringUsingEncoding:NSUTF8StringEncoding];
    path = csmString(_modelHomeDir.UTF8String) + path;

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
    return _userModel ? _userModel->_modelMatrix : nullptr;
}

@end
