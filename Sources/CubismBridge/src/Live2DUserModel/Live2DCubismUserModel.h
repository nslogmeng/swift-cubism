//
//  Live2DCubismUserModel.h
//  Cubism
//
//  Created by Meng on 2025/9/1.
//

#import <Foundation/Foundation.h>
#import <Model/CubismUserModel.hpp>
#import <CubismDefaultParameterId.hpp>

using namespace Live2D::Cubism::Framework;
using namespace Live2D::Cubism::Framework::DefaultParameterId;

namespace Live2D { namespace Cubism {

// 继承 CubismUserModel 以访问受保护的成员
class Live2DCubismUserModel: public CubismUserModel {
public:
    Live2DCubismUserModel(): CubismUserModel() {}
    virtual ~Live2DCubismUserModel() {}

    // MARK: - class property

    // property: model
    // setup from `LoadModel()`
    // get model from super `GetModel()`

    // property: moc
    // setup from `LoadModel()`
    CubismMoc* GetMoc() const { return _moc; }

    // property: modelMatrix
    // get with super `GetModelMatrix()`

    // property: motionManager
    // setup from initialize
    CubismMotionManager* GetMotionManager() const { return _motionManager; }

    // property: expressionManager
    // setup from initialize
    CubismExpressionMotionManager* GetExpressionManager() const { return _expressionManager; }

    // property: dragManager
    // setup from initialize
    // set drag(x, y) wtih super `SetDragging(x, y)`
    CubismTargetPoint* GetDragManager() const { return _dragManager; }

    // setup from `LoadPose()`
    CubismPose* GetPose() const { return _pose; }

    // setup from `LoadPhysics()`
    CubismPhysics* GetPhysics() const { return _physics; }

    // setup from `LoadUserData()`
    CubismModelUserData* GetModelUserData() const { return _modelUserData; }

    // property: eyeBlink
    CubismEyeBlink* GetEyeBlink() const { return _eyeBlink; }
    void SetEyeBlink(CubismEyeBlink *e) { _eyeBlink = e; }

    // property: breath
    CubismBreath* GetBreath() const { return _breath; }
    void SetBreath(CubismBreath *b) { _breath = b; }

    // render access from super:
    //
    // `CreateRenderer(v)`
    // `DeleteRenderer()`
    // `GetRenderer()`

    // MARK: - value property

    // property: initialized
    // get wtih super `IsInitialized()`
    // set with `SetInitialized(v)` override super `IsInitialized(v)`
    void SetInitialized(csmBool v) { _initialized = v; }

    // proeprty: updating
    // get with super `IsUpdating()`
    // set with `SetUpdating(v)` override super `IsUpdating(v)`
    void SetUpdating(csmBool v) { _updating = v; }

    // property: opacity
    // get with super `GetOpacity()`
    // set with super `SetOpacity(a)`

    // property: accelerationX/accelerationY/accelerationZ
    // set with super `SetAcceleration(x, y, z)`

    // property: lipSync
    csmBool GetLipSync() const { return _lipSync; }
    void SetLipSync(csmBool v) { _lipSync = v; }

    // property: lastLipSyncValue
    csmFloat32 GetLastLipSyncValue() const { return _lastLipSyncValue; }
    void SetLastLipSyncValue(csmFloat32 v) { _lastLipSyncValue = v; }

    // property: mocConsistency
    csmBool GetMocConsistency() const { return _mocConsistency; }
    void SetMocConsistency(csmBool v) { _mocConsistency = v; }

    // property: motionConsistency
    csmBool GetMotionConsistency() const { return _motionConsistency; }
    void SetMotionConsistency(csmBool v) { _motionConsistency = v; }

    // property: debugMode
    csmBool IsDebugMode() const { return _debugMode; }
    void SetDebugMode(csmBool v) { _debugMode = v; }
};

}}
