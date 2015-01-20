//
//  KMDAboutViewController.m
//  KMD Common
//
//  Created by Henning Böttger on 17/05/13.
//  Copyright (c) 2013 KMD A/S. All rights reserved.
//

#import "KMDAboutViewController.h"
#import "UIImage+ImageEffects.h"

static UIImage *__backgroundImage;
static NSString *__applicationName;
static NSString *__applicationVersion;

@interface KMDAboutViewController ()

@end

@implementation KMDAboutViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    UIImageView *backgroundView = [[UIImageView alloc] init];
//    if (__backgroundImage)
//    {
//        backgroundView.image = __backgroundImage;
//    }
//    self.tableView.backgroundView = backgroundView;
    
    NSString *appName = [[NSBundle mainBundle] localizedStringForKey:@"app_name" value:@"Missing app name" table:@"Custom"];
    NSString *appDescription = [[NSBundle mainBundle] localizedStringForKey:@"app_description" value:@"Missing description" table:@"Custom"];
    NSString *versionString = [NSString stringWithFormat:@"%@-%@",
                               [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                               [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    
    self.navigationItem.title = [NSString stringWithFormat:@"Om %@", appName];

    _appDescriptionTextView.text = appDescription;
    _appSupportNameLabel.text = appName;
    _appSupportVersionLabel.text = [NSString stringWithFormat:@"iOS version %@", versionString];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Initial setup

+ (void)setBackgroundImage:(UIImage *)image
{
    __backgroundImage = image;
}


#pragma mark - Table view data source

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == 1) && (indexPath.row == 0))
    {
        // www.kmd.dk
        NSString *urlWithSpecialCharacter = @"http://www.kmd.dk/da/loesninger/Kommune/KMD_Opus/%C3%98konomistyring-og-Administrativ-Styring/Pages/Personale-og-registrering.aspx";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlWithSpecialCharacter]];
    } else if ((indexPath.section == 1) && (indexPath.row == 1))
    {
        // iTunes App store
        NSString *appUrlStringToAppStore = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"KMDURLToAppInAppStore"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appUrlStringToAppStore]];
    }
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

@end
