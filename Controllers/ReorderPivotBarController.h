#import "UIKit/UIKit.h"

@interface ReorderPivotBarController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSMutableArray *tabOrder;
@end
