#import <Foundation/Foundation.h>

#define KMD_LIGHT_GREEN [UIColor colorWithRed:13.0/255.0 green:255.0/255.0 blue:201.0/255.0 alpha:1]

#define KMD_GREEN [UIColor colorWithRed:0.24 green:0.59 blue:0.09 alpha:1]
#define KMD_DARK_GREEN [UIColor colorWithRed:67.0/255.0 green:130.0/255.0 blue:45.0/255.0 alpha:1]
#define KMD_GRAY [UIColor colorWithRed:.074509804 green:.074509804 blue:.074509804 alpha:1]
#define KMD_MED_GREEN [UIColor colorWithRed:92.0/255.0 green:130.0/255.0 blue: 49.0/255.0 alpha:1]

@interface KMDAppearance : NSObject

/// Applies all common styling (theme) to font, backgrounds text color
/// etc. so it is consistent across the apps.
///
+ (void)apply;

@end
