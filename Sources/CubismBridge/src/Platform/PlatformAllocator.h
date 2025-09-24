//
//  PlatformAllocator.h
//  CubismBridge
//
//  Created by Meng on 2025/8/24.
//

#pragma once

#import <CubismFramework.hpp>

/**
 * @brief 平台相关注入接口，实现内存分配。
 *
 */
class PlatformAllocator: public Csm::ICubismAllocator {
    /**
     * @brief  分配内存区域。
     */
    void* Allocate(const Csm::csmSizeType size);

    /**
     * @brief   释放内存区域。
     */
    void Deallocate(void* memory);

    /**
     * @brief 重新分配内存区域。
     */
    void* AllocateAligned(const Csm::csmSizeType size, const Csm::csmUint32 alignment);

    /**
     * @brief 释放内存区域。
     */
    void DeallocateAligned(void* alignedMemory);
};

#pragma once
