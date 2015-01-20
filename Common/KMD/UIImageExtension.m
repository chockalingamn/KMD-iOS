#import "UIImageExtension.h"


@implementation UIImage (Bundle)

+ (UIImage *)imageNamedInBundle:(NSString *)imageName
{
    NSString * bundleImageName = [@"KMD.bundle/" stringByAppendingString:imageName];
    return [UIImage imageNamed:bundleImageName];
}

@end
