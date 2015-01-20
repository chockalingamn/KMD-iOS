#import "KMDAppearance.h"

#import <QuartzCore/QuartzCore.h>


@implementation KMDAppearance

+ (void)apply
{    
    // Navigation Bar
    
    [UINavigationBar.appearance setTintColor:KMD_GRAY];
    
    // Search Bar
    
    [UISearchBar.appearance setTintColor:KMD_GRAY];
    
    // Toolbar
    
    [UIToolbar.appearance setTintColor:KMD_GRAY];
    
    // Table View
    
    [UITableViewCell.appearance setSelectionStyle:UITableViewCellSelectionStyleGray];
}


+ (UIFont *)fontWithName:(NSString *)fontFamilyName size:(NSInteger)fontSize
{
    UIFont *font = [UIFont fontWithName:fontFamilyName size:fontSize];
    
    if (!font)
    {
        NSLog(@"The '%@' not found. Have you included it in your plist file?", fontFamilyName);
    }
    
    return font;
}

@end
