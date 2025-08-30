//
//  PlatformAllocator.cpp
//  CubismBridge
//
//  Created by Meng on 2025/8/24.
//

#include "PlatformAllocator.h"
#import <Foundation/Foundation.h>

using namespace Csm;

void* PlatformAllocator::Allocate(const csmSizeType size) {
    return malloc(size);
}

void PlatformAllocator::Deallocate(void* memory) {
    free(memory);
}

void* PlatformAllocator::AllocateAligned(const csmSizeType size, const csmUint32 alignment) {
    size_t offset, shift, alignedAddress;
    void* allocation;
    void** preamble;

    offset = alignment - 1 + sizeof(void*);

    allocation = Allocate(size + static_cast<csmUint32>(offset));

    alignedAddress = reinterpret_cast<size_t>(allocation) + sizeof(void*);

    shift = alignedAddress % alignment;

    if (shift) {
        alignedAddress += (alignment - shift);
    }

    preamble = reinterpret_cast<void**>(alignedAddress);
    preamble[-1] = allocation;

    return reinterpret_cast<void*>(alignedAddress);
}

void PlatformAllocator::DeallocateAligned(void* alignedMemory) {
    void** preamble;

    preamble = static_cast<void**>(alignedMemory);

    Deallocate(preamble[-1]);
}
