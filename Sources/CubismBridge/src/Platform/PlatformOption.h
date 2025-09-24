//
//  PlatformOption.hpp
//  Cubism
//
//  Created by Meng on 2025/8/24.
//

#pragma once

#import <string>
#import <CubismFramework.hpp>

/**
 * @brief 平台相关注入接口，Cubism Options。
 */
class PlatformOption {
public:
    /**
     * @brief 以字节数据方式读取文件
     */
    static Csm::csmByte* LoadFileAsBytes(const std::string filePath, Csm::csmSizeInt* outSize);


    /**
     * @brief 释放字节数据
     */
    static void ReleaseBytes(Csm::csmByte* byteData);

    /**
     * 输出日志
     */
    static void PrintLog(const Csm::csmChar* message);
    static void _PrintLog(const Csm::csmChar* format, ...);
};
