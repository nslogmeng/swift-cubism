//
//  Live2DCubismMotion.mm
//  Cubism
//
//  Created by Meng on 2025/8/26.
//

#import "Live2DCubismMotion.h"
#import "Live2DCubismMotion+Internal.h"
#import <Motion/ACubismMotion.hpp>

using namespace Csm;

@interface Live2DCubismMotion()

@property (nonatomic, copy, readwrite) NSString *name;

@end

@implementation Live2DCubismMotion

- (instancetype)initWithName:(NSString *)name motion:(ACubismMotion *)motion {
    self = [super init];
    if (self) {
        self.name = name;
        self.motion = motion;
    }
    return self;
}

- (void)dealloc {
    ACubismMotion::Delete(self.motion);
}

@end
