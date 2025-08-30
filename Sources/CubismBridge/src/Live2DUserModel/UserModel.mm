//
//  UserModel.mm
//  Cubism
//
//  Created by Meng on 2025/8/25.
//

#import "UserModel.h"
#import <Foundation/Foundation.h>
#import <fstream>
#import <vector>
//#import "LAppTextureManager.h"
//#import "AppDelegate.h"
#import <CubismDefaultParameterId.hpp>
#import <CubismModelSettingJson.hpp>
#import <Id/CubismIdManager.hpp>
#import <Motion/CubismMotion.hpp>
#import <Motion/CubismMotionQueueEntry.hpp>
#import <Physics/CubismPhysics.hpp>
#import <Rendering/Metal/CubismRenderer_Metal.hpp>
#import <Utils/CubismString.hpp>
#import "../Live2DCubism/Platform/Config/PlatformConfig.h"
#import "../Live2DCubism/Platform/Option/PlatformOption.h"

using namespace Live2D::Cubism::Framework;
using namespace Live2D::Cubism::Framework::DefaultParameterId;

namespace {
    csmByte* CreateBuffer(const csmChar* path, csmSizeInt* size) {
        return PlatformOption::LoadFileAsBytes(path,size);
    }

    void DeleteBuffer(csmByte* buffer, const csmChar* path = "") {
        PlatformOption::ReleaseBytes(buffer);
    }
}

UserModel::UserModel() : CubismUserModel() , _modelSetting(NULL) , _userTimeSeconds(0.0f) {
//    if (CubismModelConfig.mocConsistencyValidationEnable) {
//        _mocConsistency = true;
//    }
//
//    if (CubismModelConfig.debugLogEnable) {
//        _debugMode = true;
//    }

    _idParamAngleX = CubismFramework::GetIdManager()->GetId(ParamAngleX);
    _idParamAngleY = CubismFramework::GetIdManager()->GetId(ParamAngleY);
    _idParamAngleZ = CubismFramework::GetIdManager()->GetId(ParamAngleZ);
    _idParamBodyAngleX = CubismFramework::GetIdManager()->GetId(ParamBodyAngleX);
    _idParamEyeBallX = CubismFramework::GetIdManager()->GetId(ParamEyeBallX);
    _idParamEyeBallY = CubismFramework::GetIdManager()->GetId(ParamEyeBallY);
}

UserModel::~UserModel() {
    _renderBuffer.DestroyOffscreenSurface();

    ReleaseMotions();
    ReleaseExpressions();

    for (csmInt32 i = 0; i < _modelSetting->GetMotionGroupCount(); i++) {
        const csmChar* group = _modelSetting->GetMotionGroupName(i);
        ReleaseMotionGroup(group);
    }

    // TODO
//    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
//    LAppTextureManager *textureManager = [delegate getTextureManager];

    for (csmInt32 modelTextureNumber = 0; modelTextureNumber < _modelSetting->GetTextureCount(); modelTextureNumber++) {
        // 若纹理名为空字符串，则跳过删除处理
        if (!strcmp(_modelSetting->GetTextureFileName(modelTextureNumber), ""))
        {
            continue;
        }

        // 从纹理管理类中删除模型纹理
        csmString texturePath = _modelSetting->GetTextureFileName(modelTextureNumber);
        texturePath = _modelHomeDir + texturePath;
//        [textureManager releaseTextureByName:texturePath.GetRawString()];
    }

    delete _modelSetting;
}

void UserModel::LoadAssets(const csmChar* dir, const csmChar* fileName) {
    _modelHomeDir = dir;

    if (_debugMode) {
        PlatformOption::_PrintLog("[APP]load model setting: %s", fileName);
    }

    csmSizeInt size;
    const csmString path = csmString(dir) + fileName;

    csmByte* buffer = CreateBuffer(path.GetRawString(), &size);
    ICubismModelSetting* setting = new CubismModelSettingJson(buffer, size);
    DeleteBuffer(buffer, path.GetRawString());

    SetupModel(setting);

    if (_model == NULL) {
        PlatformOption::_PrintLog("Failed to LoadAssets().");
        return;
    }

    CreateRenderer();

    SetupTextures();
}


void UserModel::SetupModel(ICubismModelSetting* setting) {
    _updating = true;
    _initialized = false;

    _modelSetting = setting;

    csmByte* buffer;
    csmSizeInt size;

    // Cubism模型
    if (strcmp(_modelSetting->GetModelFileName(), "") != 0) {
        csmString path = _modelSetting->GetModelFileName();
        path = _modelHomeDir + path;

        if (_debugMode) {
            PlatformOption::_PrintLog("[APP]create model: %s", setting->GetModelFileName());
        }

        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadModel(buffer, size, _mocConsistency);
        DeleteBuffer(buffer, path.GetRawString());
    }

    // 表情
    if (_modelSetting->GetExpressionCount() > 0) {
        const csmInt32 count = _modelSetting->GetExpressionCount();
        for (csmInt32 i = 0; i < count; i++) {
            csmString name = _modelSetting->GetExpressionName(i);
            csmString path = _modelSetting->GetExpressionFileName(i);
            path = _modelHomeDir + path;

            buffer = CreateBuffer(path.GetRawString(), &size);
            ACubismMotion* motion = LoadExpression(buffer, size, name.GetRawString());

            if (motion)
            {
                if (_expressions[name] != NULL)
                {
                    ACubismMotion::Delete(_expressions[name]);
                    _expressions[name] = NULL;
                }
                _expressions[name] = motion;
            }

            DeleteBuffer(buffer, path.GetRawString());
        }
    }

    // 物理
    if (strcmp(_modelSetting->GetPhysicsFileName(), "") != 0) {
        csmString path = _modelSetting->GetPhysicsFileName();
        path = _modelHomeDir + path;

        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadPhysics(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }

    // 姿势
    if (strcmp(_modelSetting->GetPoseFileName(), "") != 0) {
        csmString path = _modelSetting->GetPoseFileName();
        path = _modelHomeDir + path;

        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadPose(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }

    // 眨眼
    if (_modelSetting->GetEyeBlinkParameterCount() > 0) {
        _eyeBlink = CubismEyeBlink::Create(_modelSetting);
    }

    // 呼吸
    {
        _breath = CubismBreath::Create();

        csmVector<CubismBreath::BreathParameterData> breathParameters;

        breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamAngleX, 0.0f, 15.0f, 6.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamAngleY, 0.0f, 8.0f, 3.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamAngleZ, 0.0f, 10.0f, 5.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(_idParamBodyAngleX, 0.0f, 4.0f, 15.5345f, 0.5f));
        breathParameters.PushBack(CubismBreath::BreathParameterData(CubismFramework::GetIdManager()->GetId(ParamBreath), 0.5f, 0.5f, 3.2345f, 0.5f));

        _breath->SetParameters(breathParameters);
    }

    // 用户数据
    if (strcmp(_modelSetting->GetUserDataFile(), "") != 0) {
        csmString path = _modelSetting->GetUserDataFile();
        path = _modelHomeDir + path;
        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadUserData(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }

    // EyeBlinkIds
    {
        csmInt32 eyeBlinkIdCount = _modelSetting->GetEyeBlinkParameterCount();
        for (csmInt32 i = 0; i < eyeBlinkIdCount; ++i)
        {
            _eyeBlinkIds.PushBack(_modelSetting->GetEyeBlinkParameterId(i));
        }
    }

    // LipSyncIds
    {
        csmInt32 lipSyncIdCount = _modelSetting->GetLipSyncParameterCount();
        for (csmInt32 i = 0; i < lipSyncIdCount; ++i)
        {
            _lipSyncIds.PushBack(_modelSetting->GetLipSyncParameterId(i));
        }
    }

    if (_modelSetting == NULL || _modelMatrix == NULL) {
        PlatformOption::PrintLog("Failed to SetupModel().");
        return;
    }

    // 布局
    csmMap<csmString, csmFloat32> layout;
    _modelSetting->GetLayoutMap(layout);
    _modelMatrix->SetupFromLayout(layout);

    _model->SaveParameters();

    for (csmInt32 i = 0; i < _modelSetting->GetMotionGroupCount(); i++) {
        const csmChar* group = _modelSetting->GetMotionGroupName(i);
        PreloadMotionGroup(group);
    }

    _motionManager->StopAllMotions();

    _updating = false;
    _initialized = true;
}

void UserModel::PreloadMotionGroup(const csmChar* group) {
    const csmInt32 count = _modelSetting->GetMotionCount(group);

    for (csmInt32 i = 0; i < count; i++) {
        // 例如 idle_0
        csmString name = Utils::CubismString::GetFormatedString("%s_%d", group, i);
        csmString path = _modelSetting->GetMotionFileName(group, i);
        path = _modelHomeDir + path;

        if (_debugMode) {
            PlatformOption::_PrintLog("[APP]load motion: %s => [%s_%d] ", path.GetRawString(), group, i);
        }

        csmByte* buffer;
        csmSizeInt size;
        buffer = CreateBuffer(path.GetRawString(), &size);
        CubismMotion* tmpMotion = static_cast<CubismMotion*>(LoadMotion(buffer, size, name.GetRawString(), NULL, NULL, _modelSetting, group, i));

        if (tmpMotion) {
            tmpMotion->SetEffectIds(_eyeBlinkIds, _lipSyncIds);

            if (_motions[name] != NULL)
            {
                ACubismMotion::Delete(_motions[name]);
            }
            _motions[name] = tmpMotion;
        }

        DeleteBuffer(buffer, path.GetRawString());
    }
}

void UserModel::ReleaseMotionGroup(const csmChar* group) const {
    const csmInt32 count = _modelSetting->GetMotionCount(group);
    for (csmInt32 i = 0; i < count; i++) {
        csmString voice = _modelSetting->GetMotionSoundFileName(group, i);
        if (strcmp(voice.GetRawString(), "") != 0)
        {
            csmString path = voice;
            path = _modelHomeDir + path;
        }
    }
}

void UserModel::ReleaseMotions() {
    for (csmMap<csmString, ACubismMotion*>::const_iterator iter = _motions.Begin(); iter != _motions.End(); ++iter) {
        ACubismMotion::Delete(iter->Second);
    }

    _motions.Clear();
}

void UserModel::ReleaseExpressions() {
    for (csmMap<csmString, ACubismMotion*>::const_iterator iter = _expressions.Begin(); iter != _expressions.End(); ++iter) {
        ACubismMotion::Delete(iter->Second);
    }

    _expressions.Clear();
}

void UserModel::Update() {
    const csmFloat32 deltaTimeSeconds = 0.0; // LAppPal::GetDeltaTime(); TODO
    _userTimeSeconds += deltaTimeSeconds;

    _dragManager->Update(deltaTimeSeconds);
    _dragX = _dragManager->GetX();
    _dragY = _dragManager->GetY();

    // 通过动作更新参数的有无
    csmBool motionUpdated = false;

    //-----------------------------------------------------------------
    _model->LoadParameters(); // 加载上次保存的状态
    _model->LoadParameters(); // 加载上次保存的状态
    if (_motionManager->IsFinished()) {
        // 若没有动作播放，则从待机动作中随机播放一个
        // TODO
        StartRandomMotion([CubismModelConfig.motionGroupIdle cStringUsingEncoding:NSUTF8StringEncoding], (signed int)CubismModelConfig.priorityIdle);
    } else {
        motionUpdated = _motionManager->UpdateMotion(_model, deltaTimeSeconds); // 更新动作
    }
    _model->SaveParameters(); // 保存状态
    //-----------------------------------------------------------------

    // 不透明度
    _opacity = _model->GetModelOpacity();

    // 眨眼
    if (!motionUpdated) {
        if (_eyeBlink != NULL) {
            // 主动作未更新时
            _eyeBlink->UpdateParameters(_model, deltaTimeSeconds); // 眨眼
        }
    }

    if (_expressionManager != NULL) {
        _expressionManager->UpdateMotion(_model, deltaTimeSeconds); // 通过表情更新参数（相对变化）
    }

    // 拖拽变化
    // 通过拖拽调整脸部朝向
    _model->AddParameterValue(_idParamAngleX, _dragX * 30); // 添加-30到30的值
    _model->AddParameterValue(_idParamAngleY, _dragY * 30);
    _model->AddParameterValue(_idParamAngleZ, _dragX * _dragY * -30);

    // 通过拖拽调整身体朝向
    _model->AddParameterValue(_idParamBodyAngleX, _dragX * 10); // 添加-10到10的值

    // 通过拖拽调整眼睛朝向
    _model->AddParameterValue(_idParamEyeBallX, _dragX); // 添加-1到1的值
    _model->AddParameterValue(_idParamEyeBallY, _dragY);

    // 呼吸等
    if (_breath != NULL) {
        _breath->UpdateParameters(_model, deltaTimeSeconds);
    }

    // 物理运算设置
    if (_physics != NULL) {
        _physics->Evaluate(_model, deltaTimeSeconds);
    }

    // 唇形同步设置
    if (_lipSync) {
        csmFloat32 value = 0; // 若实时唇形同步，从系统获取音量并输入0~1范围的值

        for (csmUint32 i = 0; i < _lipSyncIds.GetSize(); ++i)
        {
            _model->AddParameterValue(_lipSyncIds[i], value, 0.8f);
        }
    }

    // 姿势设置
    if (_pose != NULL) {
        _pose->UpdateParameters(_model, deltaTimeSeconds);
    }

    _model->Update();

}

CubismMotionQueueEntryHandle UserModel::StartMotion(const csmChar* group, csmInt32 no, csmInt32 priority, ACubismMotion::FinishedMotionCallback onFinishedMotionHandler, ACubismMotion::BeganMotionCallback onBeganMotionHandler) {
    if (priority == 1 /* PriorityForce TODO */) {
        _motionManager->SetReservePriority(priority);
    } else if (!_motionManager->ReserveMotion(priority)) {
        if (_debugMode) {
            PlatformOption::PrintLog("[APP]can't start motion.");
        }
        return InvalidMotionQueueEntryHandleValue;
    }

    const csmString fileName = _modelSetting->GetMotionFileName(group, no);

    // 例如 idle_0
    csmString name = Utils::CubismString::GetFormatedString("%s_%d", group, no);
    CubismMotion* motion = static_cast<CubismMotion*>(_motions[name.GetRawString()]);
    csmBool autoDelete = false;

    if (motion == NULL) {
        csmString path = fileName;
        path = _modelHomeDir + path;

        csmByte* buffer;
        csmSizeInt size;
        buffer = CreateBuffer(path.GetRawString(), &size);
        motion = static_cast<CubismMotion*>(LoadMotion(buffer, size, NULL, onFinishedMotionHandler, NULL, _modelSetting, group, no));

        if (motion) {
            motion->SetEffectIds(_eyeBlinkIds, _lipSyncIds);
            autoDelete = true; // 終了時にメモリから削除
        }

        DeleteBuffer(buffer, path.GetRawString());
    } else {
        motion->SetBeganMotionHandler(onBeganMotionHandler);
        motion->SetFinishedMotionHandler(onFinishedMotionHandler);
    }

    //voice
    csmString voice = _modelSetting->GetMotionSoundFileName(group, no);
    if (strcmp(voice.GetRawString(), "") != 0) {
        csmString path = voice;
        path = _modelHomeDir + path;
    }

    if (_debugMode) {
        PlatformOption::_PrintLog("[APP]start motion: [%s_%d]", group, no);
    }
    return  _motionManager->StartMotionPriority(motion, autoDelete, priority);
}

CubismMotionQueueEntryHandle UserModel::StartRandomMotion(const csmChar* group, csmInt32 priority, ACubismMotion::FinishedMotionCallback onFinishedMotionHandler, ACubismMotion::BeganMotionCallback onBeganMotionHandler) {
    if (_modelSetting->GetMotionCount(group) == 0) {
        return InvalidMotionQueueEntryHandleValue;
    }

    csmInt32 no = rand() % _modelSetting->GetMotionCount(group);

    return StartMotion(group, no, priority, onFinishedMotionHandler, onBeganMotionHandler);
}

void UserModel::DoDraw() {
    if (_model == NULL) {
        return;
    }

    GetRenderer<Rendering::CubismRenderer_Metal>()->DrawModel();
}

void UserModel::Draw(CubismMatrix44& matrix) {
    if (_model == NULL) {
        return;
    }

    matrix.MultiplyByMatrix(_modelMatrix);

    GetRenderer<Rendering::CubismRenderer_Metal>()->SetMvpMatrix(&matrix);

    DoDraw();
}

csmBool UserModel::HitTest(const csmChar* hitAreaName, csmFloat32 x, csmFloat32 y) {
    // 若透明则无判定
    if (_opacity < 1)
    {
        return false;
    }
    const csmInt32 count = _modelSetting->GetHitAreasCount();
    for (csmInt32 i = 0; i < count; i++)
    {
        if (strcmp(_modelSetting->GetHitAreaName(i), hitAreaName) == 0)
        {
            const CubismIdHandle drawID = _modelSetting->GetHitAreaId(i);
            return IsHit(drawID, x, y);
        }
    }
    return false; // 若不存在则返回false
}

void UserModel::SetExpression(const csmChar* expressionID) {
    ACubismMotion* motion = _expressions[expressionID];
    if (_debugMode) {
        PlatformOption::_PrintLog("[APP]expression: [%s]", expressionID);
    }

    if (motion != NULL) {
        _expressionManager->StartMotion(motion, false);
    } else {
        if (_debugMode) {
            PlatformOption::_PrintLog("[APP]expression[%s] is null ", expressionID);
        }
    }
}

void UserModel::SetRandomExpression() {
    if (_expressions.GetSize() == 0) {
        return;
    }

    csmInt32 no = rand() % _expressions.GetSize();
    csmMap<csmString, ACubismMotion*>::const_iterator map_ite;
    csmInt32 i = 0;
    for (map_ite = _expressions.Begin(); map_ite != _expressions.End(); map_ite++) {
        if (i == no) {
            csmString name = (*map_ite).First;
            SetExpression(name.GetRawString());
            return;
        }
        i++;
    }
}

void UserModel::ReloadRenderer() {
    DeleteRenderer();

    CreateRenderer();

    SetupTextures();
}

void UserModel::SetupTextures() {
    for (csmInt32 modelTextureNumber = 0; modelTextureNumber < _modelSetting->GetTextureCount(); modelTextureNumber++) {
        // 若纹理名为空字符串，则跳过加载和绑定处理
        if (!strcmp(_modelSetting->GetTextureFileName(modelTextureNumber), "")) {
            continue;
        }

        // 加载到Metal纹理
        csmString texturePath = _modelSetting->GetTextureFileName(modelTextureNumber);
        texturePath = _modelHomeDir + texturePath;

        // TODO
//        AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
//        TextureInfo* texture = nil // [[delegate getTextureManager] createTextureFromPngFile:texturePath.GetRawString()];
//        id <MTLTexture> mtlTextueNumber = texture->id;
//
//        // Metal
//        GetRenderer<Rendering::CubismRenderer_Metal>()->BindTexture(modelTextureNumber, mtlTextueNumber);
    }

#ifdef PREMULTIPLIED_ALPHA_ENABLE
    GetRenderer<Rendering::CubismRenderer_Metal>()->IsPremultipliedAlpha(true);
#else
    GetRenderer<Rendering::CubismRenderer_Metal>()->IsPremultipliedAlpha(false);
#endif
}

void UserModel::MotionEventFired(const csmString& eventValue) {
    CubismLogInfo("%s is fired on LAppModel!!", eventValue.GetRawString());
}

Csm::Rendering::CubismOffscreenSurface_Metal& UserModel::GetRenderBuffer() {
    return _renderBuffer;
}

csmBool UserModel::HasMocConsistencyFromFile(const csmChar* mocFileName) {
    CSM_ASSERT(strcmp(mocFileName, ""));

    csmByte* buffer;
    csmSizeInt size;

    csmString path = mocFileName;
    path = _modelHomeDir + path;

    buffer = CreateBuffer(path.GetRawString(), &size);

    csmBool consistency = CubismMoc::HasMocConsistencyFromUnrevivedMoc(buffer, size);
    if (!consistency) {
        CubismLogInfo("Inconsistent MOC3.");
    } else {
        CubismLogInfo("Consistent MOC3.");
    }

    DeleteBuffer(buffer);

    return consistency;
}

