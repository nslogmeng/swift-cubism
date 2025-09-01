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
#import <Id/CubismIdManager.hpp>
#import <CubismDefaultParameterId.hpp>

@interface Live2DUserModel()

@end

@implementation Live2DUserModel

- (nullable instancetype)initWithHomeDir:(NSString *)homeDir fileName:(NSString *)fileName error:(NSError **)error {
    self = [super init];
    if (self) {
        self.setting = [[Live2DModelSetting alloc] initWithHomeDir:homeDir fileName:fileName error: error];

        if ((error && *error) || !_setting) {
            return nil;
        }

        self.angleX = CubismFramework::GetIdManager()->GetId(ParamAngleX);
        self.angleY = CubismFramework::GetIdManager()->GetId(ParamAngleY);
        self.angleZ = CubismFramework::GetIdManager()->GetId(ParamAngleZ);
        self.bodyAngleX = CubismFramework::GetIdManager()->GetId(ParamBodyAngleX);
        self.eyeBallX = CubismFramework::GetIdManager()->GetId(ParamEyeBallX);
        self.eyeBallY = CubismFramework::GetIdManager()->GetId(ParamEyeBallY);
    }
    return self;
}

- (void)loadModelWithError:(NSError **)error {
    const csmChar *modelFileName = self.setting.modelSetting->GetModelFileName();
    if (strcmp(modelFileName, "") == 0) {
        PlatformConfig.logHandler([NSString stringWithFormat:@"load model file failed: %s", modelFileName]);
        return;
    }
}

@end
