#import "KMDTableViewController.h"

#import "KMDAppearance.h"
#import "KMDTableViewCell.h"


@implementation KMDTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorColor = KMD_GRAY;
    
    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"KMD.bundle/TableViewBackground"]];
    background.frame = self.tableView.bounds;
    
    self.tableView.backgroundView = background;
    
    for (NSInteger i = 0; i < [self.tableView numberOfSections]; i++)
    {
        for (NSInteger j = 0; j < [self.tableView numberOfRowsInSection:i]; j++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
            
            KMDTableViewCell *cell = (KMDTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell updateSelectedBackground:indexPath];
        }
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil || [sectionTitle isEqualToString:@""]) {
        return nil;
    }

    // Create label with section title

    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 0, 280, kTableViewHeaderHeight);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor blackColor];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.font = [UIFont boldSystemFontOfSize:16];
    label.text = sectionTitle;

    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kTableViewHeaderHeight)];

    view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"KMD.bundle/TableViewHeaderBackground"]];

    [view addSubview:label];

    return view;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil || [sectionTitle isEqualToString:@""]) {
        return 0;
    }
    
    return kTableViewHeaderHeight;
}

@end
