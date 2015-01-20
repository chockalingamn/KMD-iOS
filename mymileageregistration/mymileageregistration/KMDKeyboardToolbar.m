//
//  KMDKeyboardToolbar.m
//  mymileageregistration
//
//  Created by Per Friis on 04/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import "KMDKeyboardToolbar.h"

@interface KMDKeyboardToolbar() <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *buttons;
@property (nonatomic, weak) IBOutlet UIButton *hideButton;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIImageView *poweredbygoogleImageView;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, readwrite) CGFloat maxHeight;

@end

@implementation KMDKeyboardToolbar

- (void)setSuggestions:(NSArray *)suggestions{
    _suggestions = suggestions;
    if ((!_suggestions || _suggestions.count == 0) && CGRectGetHeight(self.frame) >= 32.0f) {
        __block CGRect rect = self.frame;
        rect.size.height = 32.0;
        rect.origin.y = 0;
        
            self.frame = rect;
            self.tableView.alpha = 0.0f;
    } else {
        CGRect rect = self.frame;
 
        rect.size.height = 32.0f + _maxHeight;
        rect.origin.y = -_maxHeight;


        self.frame = rect;
        self.poweredbygoogleImageView.alpha = .3f;
            self.tableView.alpha = 1.0f;

    }
    
    [self.tableView reloadData];
}
- (void)awakeFromNib{
    [super awakeFromNib];
    if (CGRectGetHeight([UIScreen mainScreen].bounds) > 480) {
        _maxHeight = 180;
    } else {
        _maxHeight = 110;
    }
    
    if ([UIVisualEffectView class]) {
        self.backgroundColor = [UIColor clearColor];
        UIVisualEffectView *effetctView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        effetctView.frame = [UIScreen mainScreen].bounds;
        self.clipsToBounds = YES;
        [self addSubview:effetctView];
        [self sendSubviewToBack:effetctView];
    }
    
    if (_tableView) {
        _tableView.layer.borderColor = [[UIColor colorWithWhite:0.1 alpha:0.5] CGColor];
        _tableView.layer.borderWidth = 0.5;
        _tableView.layer.cornerRadius =  3.0f;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = [UIColor clearColor];
    }
}


-(void)layoutSubviews{
    [super layoutSubviews];
    
    if (![UIVisualEffectView class]) {
        if (self.backgroundImage) {
            self.backgroundColor = [UIColor colorWithPatternImage:self.backgroundImage];
        } else {
            self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:.9f];
        }
    }
    
    
    
    CGFloat height = CGRectGetHeight(self.frame);
    if (height > 32) {
        self.tableView.frame = CGRectInset(CGRectMake(0, 0, CGRectGetWidth(self.frame), height - 32),3,3);
        
    } else {
        self.tableView.frame = CGRectZero;
    }
    
    self.poweredbygoogleImageView.frame = CGRectMake(CGRectGetWidth(self.frame) - 75,10, 65, 22);
    if (CGRectGetHeight(self.frame) <= 32.0f) {
        self.poweredbygoogleImageView.alpha = 0;
    }
    
    
    for (UIButton *button in self.buttons) {
        CGRect rect = button.frame;
        rect.origin.y =  height - 31.0;
        button.frame = rect;
    };
    
    
    CGRect rect = self.hideButton.frame;
    rect.origin.y = height - 28;
    rect.origin.x = CGRectGetWidth(self.frame) - CGRectGetWidth(rect) - 5;
    self.hideButton.frame = rect;
}

- (void)setKey:(NSString *)key{
    _key = key;
    
    if (key) {
        self.values = [[NSUserDefaults standardUserDefaults] objectForKey:_key];
    } else {
        self.values = nil;
    }
    
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        if (idx < self.values.count) {
            NSDictionary *obj = [self.values objectAtIndex:idx];
            [button setTitle:[obj valueForKey:@"string"] forState:UIControlStateNormal];
        } else {
            [button setTitle:@"" forState:UIControlStateNormal];
        }
    }];
}

- (IBAction)buttonPressed:(UIButton *)sender{
    if (sender.titleLabel.text && sender.titleLabel.text.length > 0) {
        
        if ([self.delegate respondsToSelector:@selector(keyboardToolbarValue:forKey:)]) {
            [self.delegate keyboardToolbarValue:sender.titleLabel.text forKey:self.key];
        }
    }
}

- (IBAction)removeStandardText:(UIButton *)sender{
    NSString *string = sender.titleLabel.text;
    
    NSMutableArray *newlist = [[NSMutableArray alloc] initWithArray:[self.values filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"string != %@",string]]];
    
    self.values = newlist;
    [[NSUserDefaults standardUserDefaults] setObject:self.values forKey:self.key];
    self.key = self.key;
}


- (IBAction)dismissKeyboard:(id)sender{
    if ([self.delegate respondsToSelector:@selector(keyboardToolbarDismissKeyboard)]) {
        [self.delegate keyboardToolbarDismissKeyboard];
    }
}

- (NSArray *)updateListWithString:(NSString *)string{
    return [self updateList:self.values withString:string];
}

- (NSArray *)updateList:(NSArray *)list withString:(NSString *)string{
    if (!self.key) {
        return nil;
    }
    
    if (!list) {
        list = [[NSArray alloc] init];
    }
    
    NSMutableArray *newlist = [[NSMutableArray alloc] initWithArray:[list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"string != %@",string]]];
    
    list = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"string == %@",string]];
    if (list.count > 0) {
        [list enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [newlist addObject:@{@"string":[obj valueForKey:@"string"],@"count":[NSNumber numberWithInteger:[[obj valueForKey:@"count"] integerValue]+1 ]}];
        }];
    } else {
        [newlist addObject:@{@"string":string,@"count":@1}];
    }
    
    [newlist sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"count" ascending:NO]]];
    self.values = newlist;
    
    [[NSUserDefaults standardUserDefaults] setObject:self.values forKey:self.key];
    
    return newlist;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.suggestions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = [self.suggestions objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.delegate keyboardToolbarValue:self.suggestions[indexPath.row] forKey:self.key];
}
@end
