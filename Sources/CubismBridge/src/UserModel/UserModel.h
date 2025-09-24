//
//  UserModel.h
//  Cubism
//
//  Created by Meng on 2025/8/25.
//

#pragma once

#import <CubismFramework.hpp>
#import <Model/CubismUserModel.hpp>
#import <ICubismModelSetting.hpp>
#import <Type/csmRectF.hpp>
#import <Rendering/Metal/CubismOffscreenSurface_Metal.hpp>

/**
 * @brief 用户实际使用的模型实现类<br>
 *        负责模型生成、功能组件生成、更新处理和渲染调用。
 *
 */
class UserModel : public Csm::CubismUserModel {
public:
    UserModel();
    virtual ~UserModel();

    /**
     * @brief 根据 model3.json 所在目录和文件路径生成模型
     *
     */
    void LoadAssets(const Csm::csmChar* dir, const  Csm::csmChar* fileName);

    /**
     * @brief 重新构建渲染器
     *
     */
    void ReloadRenderer();

    /**
     * @brief   模型的更新处理。根据模型参数决定绘制状态。
     *
     */
    void Update();

    /**
     * @brief   绘制模型。传递模型绘制空间的 View-Projection 矩阵。
     *
     * @param[in]  matrix  View-Projection矩阵
     */
    void Draw(Csm::CubismMatrix44& matrix);

    /**
     * @brief   开始播放指定参数的动作。
     *
     * @param[in]   group                       动作组名
     * @param[in]   no                          组内编号
     * @param[in]   priority                    优先级
     * @param[in]   onFinishedMotionHandler     动作播放结束时回调。为NULL时不调用。
     * @param[in]   onBeganMotionHandler        动作播放开始时回调。为NULL时不调用。
     * @return                                  返回开始的动作标识号。用于判断单个动作是否结束。无法开始时返回“-1”
     */
    Csm::CubismMotionQueueEntryHandle StartMotion(const Csm::csmChar* group, Csm::csmInt32 no, Csm::csmInt32 priority, Csm::ACubismMotion::FinishedMotionCallback onFinishedMotionHandler = NULL, Csm::ACubismMotion::BeganMotionCallback onBeganMotionHandler = NULL);

    /**
     * @brief   随机选择动作并开始播放。
     *
     * @param[in]   group                       动作组名
     * @param[in]   priority                    优先级
     * @param[in]   onFinishedMotionHandler     动作播放结束时回调。为NULL时不调用。
     * @param[in]   onBeganMotionHandler        动作播放开始时回调。为NULL时不调用。
     * @return                                  返回开始的动作标识号。用于判断单个动作是否结束。无法开始时返回“-1”
     */
    Csm::CubismMotionQueueEntryHandle StartRandomMotion(const Csm::csmChar* group,
                                                        Csm::csmInt32 priority,
                                                        Csm::ACubismMotion::FinishedMotionCallback onFinishedMotionHandler = NULL,
                                                        Csm::ACubismMotion::BeganMotionCallback onBeganMotionHandler = NULL);

    /**
     * @brief   设置指定参数的表情动作
     *
     * @param   expressionID    表情动作ID
     */
    void SetExpression(const Csm::csmChar* expressionID);

    /**
     * @brief   随机设置表情动作
     *
     */
    void SetRandomExpression();

    /**
     * @brief   接收事件触发
     *
     */
    virtual void MotionEventFired(const Live2D::Cubism::Framework::csmString& eventValue);

    /**
     * @brief    碰撞判定测试。<br>
     *            从指定ID的顶点列表计算矩形，判断坐标是否在矩形范围内。
     *
     * @param[in]   hitAreaName     要测试碰撞判定的目标ID
     * @param[in]   x               要判定的X坐标
     * @param[in]   y               要判定的Y坐标
     */
    virtual Csm::csmBool HitTest(const Csm::csmChar* hitAreaName, Csm::csmFloat32 x, Csm::csmFloat32 y);

    /**
     * @brief   获取用于绘制到其他目标的缓冲区
     */
    Csm::Rendering::CubismOffscreenSurface_Metal& GetRenderBuffer();

    /**
     * @brief   检查 .moc3 文件的完整性
     *
     * @param[in]   mocName MOC3文件名
     * @return      若MOC3完整则返回'true'，否则返回'false'。
     */
    Csm::csmBool HasMocConsistencyFromFile(const Csm::csmChar* mocFileName);

protected:
    /**
     * @brief  绘制模型。传递模型绘制空间的 View-Projection 矩阵。
     *
     */
    void DoDraw();

private:
    /**
     * @brief 根据 model3.json 生成模型。<br>
     *         按照 model3.json 的描述生成模型、动作、物理等组件。
     *
     * @param[in]   setting     ICubismModelSetting 实例
     *
     */
    void SetupModel(Csm::ICubismModelSetting* setting);

    /**
     * @brief 加载纹理到 Metal 纹理
     *
     */
    void SetupTextures();

    /**
     * @brief   根据组名批量加载动作数据。<br>
     *           动作数据名称由 ModelSetting 内部获取。
     *
     * @param[in]   group  动作数据组名
     */
    void PreloadMotionGroup(const Csm::csmChar* group);

    /**
     * @brief   根据组名批量释放动作数据。<br>
     *           动作数据名称由 ModelSetting 内部获取。
     *
     * @param[in]   group  动作数据组名
     */
    void ReleaseMotionGroup(const Csm::csmChar* group) const;

    /**
     * @brief 释放所有动作数据
     *
     * 释放所有动作数据。
     */
    void ReleaseMotions();

    /**
     * @brief 释放所有表情数据
     *
     * 释放所有表情数据。
     */
    void ReleaseExpressions();

    Csm::ICubismModelSetting* _modelSetting; ///< 模型设置信息
    Csm::csmString _modelHomeDir; ///< 模型设置所在目录
    Csm::csmFloat32 _userTimeSeconds; ///< 累计的时间差值[秒]
    Csm::csmVector<Csm::CubismIdHandle> _eyeBlinkIds; ///< 模型设置的眨眼功能参数ID
    Csm::csmVector<Csm::CubismIdHandle> _lipSyncIds; ///< 模型设置的口型同步功能参数ID
    Csm::csmMap<Csm::csmString, Csm::ACubismMotion*>   _motions; ///< 已加载的动作列表
    Csm::csmMap<Csm::csmString, Csm::ACubismMotion*>   _expressions; ///< 已加载的表情列表
    Csm::csmVector<Csm::csmRectF> _hitArea;
    Csm::csmVector<Csm::csmRectF> _userArea;
    const Csm::CubismId* _idParamAngleX; ///< 参数ID: ParamAngleX
    const Csm::CubismId* _idParamAngleY; ///< 参数ID: ParamAngleX
    const Csm::CubismId* _idParamAngleZ; ///< 参数ID: ParamAngleX
    const Csm::CubismId* _idParamBodyAngleX; ///< 参数ID: ParamBodyAngleX
    const Csm::CubismId* _idParamEyeBallX; ///< 参数ID: ParamEyeBallX
    const Csm::CubismId* _idParamEyeBallY; ///< 参数ID: ParamEyeBallXY

    Live2D::Cubism::Framework::Rendering::CubismOffscreenSurface_Metal _renderBuffer;
};
