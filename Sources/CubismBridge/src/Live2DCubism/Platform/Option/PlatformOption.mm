//
//  PlatformOption.cpp
//  Cubism
//
//  Created by Meng on 2025/8/24.
//

#include "PlatformOption.h"
#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#import <stdarg.h>
#import <sys/stat.h>
#import <iostream>
#import <fstream>
#import "../Config/PlatformConfig.h"

using std::endl;
using namespace Csm;
using namespace std;

csmByte* PlatformOption::LoadFileAsBytes(const string filePath, csmSizeInt* outSize) {
    NSData *data;
    NSString *nsFilePath = [NSString stringWithCString:filePath.c_str() encoding:NSUTF8StringEncoding];

    if (PlatformConfig.loadFileHandler) {
        data = PlatformConfig.loadFileHandler(nsFilePath);
    } else {
        // fallback load
        NSData *data = [NSData dataWithContentsOfFile:nsFilePath];
    }

    if (data == nil) {
        _PrintLog("File load failed : %s", filePath.c_str());
        return NULL;
    }

    if (data.length == 0) {
        _PrintLog("File is loaded but file size is zero : %s", filePath.c_str());
        return NULL;
    }

    NSUInteger len = [data length];
    Byte *byteData = (Byte *)malloc(len);
    memcpy(byteData, [data bytes], len);

    *outSize = static_cast<Csm::csmSizeInt>(len);
    return static_cast<Csm::csmByte*>(byteData);
}

void PlatformOption::ReleaseBytes(csmByte* byteData) {
    free(byteData);
}

void PlatformOption::_PrintLog(const csmChar* format, ...) {
    va_list args;
    Csm::csmChar buf[256];
    va_start(args, format);
    vsnprintf(buf, sizeof(buf), format, args);
    if (PlatformConfig.logHandler) {
        NSString *msg = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
        PlatformConfig.logHandler(msg);
    }
    va_end(args);
}

void PlatformOption::PrintLog(const csmChar* message) {
    _PrintLog(message);
}
