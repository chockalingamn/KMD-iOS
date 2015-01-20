//
//  KMDKeyboardToolbar.h
//  mymileageregistration
//
//  Created by Per Friis on 04/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol KMDKeyboardToolbarDelegate;


@interface KMDKeyboardToolbar : UIView
@property (nonatomic, strong) NSString *key;
@property id <KMDKeyboardToolbarDelegate> delegate;
@property (nonatomic, strong) NSArray *suggestions;
@property (nonatomic, strong) UIImage *backgroundImage;

- (NSArray *)updateListWithString:(NSString *)string;

@end

@protocol KMDKeyboardToolbarDelegate <NSObject>

@optional
- (void)keyboardToolbarValue:(NSString *)value forKey:(NSString *)key;
- (void)keyboardToolbarDismissKeyboard;

@end