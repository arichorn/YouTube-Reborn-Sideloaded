#import "DownloadsVideoController.h"
#import <Photos/Photos.h>

@interface DownloadsVideoController ()
{
    NSString *documentsDirectory;
    NSMutableArray *filePathsVideoArray;
    NSMutableArray *filePathsVideoArtworkArray;
}
- (void)coloursView;
- (void)setupVideoArrays;
@end

@implementation DownloadsVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self coloursView];

    UITableViewStyle style;
        if (@available(iOS 13, *)) {
            style = UITableViewStyleInsetGrouped;
        } else {
            style = UITableViewStyleGrouped;
        }

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:style];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    [self setupVideoArrays];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.tableView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.tableView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
        [self.tableView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor]
    ]];
}

UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonTapped)];
self.navigationItem.rightBarButtonItem = searchButton;

- (void)searchButtonTapped {
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 44)];
    searchBar.delegate = self;
    self.tableView.tableHeaderView = searchBar;
    [searchBar becomeFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.lastPathComponent CONTAINS[cd] %@", searchText];
        self.filteredVideoArray = [[filePathsVideoArray filteredArrayUsingPredicate:predicate] mutableCopy];
    } else {
        self.filteredVideoArray = [filePathsVideoArray mutableCopy];
    }
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    self.tableView.tableHeaderView = nil;
    self.filteredVideoArray = [filePathsVideoArray mutableCopy];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tableHeaderView) {
        return self.filteredVideoArray.count;
    } else {
        return filePathsVideoArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"VideoDownloadsTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
            cell.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            cell.textLabel.textColor = [UIColor blackColor];
            cell.detailTextLabel.textColor = [UIColor blackColor];
        }
        else {
            cell.backgroundColor = [UIColor colorWithRed:0.110 green:0.110 blue:0.118 alpha:1.0];
            cell.textLabel.textColor = [UIColor whiteColor];
	    cell.textLabel.shadowColor = [UIColor blackColor];
            cell.textLabel.shadowOffset = CGSizeMake(1.0, 1.0);
            cell.detailTextLabel.textColor = [UIColor whiteColor];
        }
    }
    cell.textLabel.text = [filePathsVideoArray objectAtIndex:indexPath.row];
    @try {
        NSString *artworkFileName = filePathsVideoArtworkArray[indexPath.row];
        cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", [documentsDirectory stringByAppendingPathComponent:artworkFileName]]];
    }
    @catch (NSException *exception) {
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *currentFileName = filePathsVideoArray[indexPath.row];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:currentFileName];
    
    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    playerViewController.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:filePath]];
    playerViewController.allowsPictureInPicturePlayback = NO;
    if (@available(iOS 14.2, *)) {
        playerViewController.canStartPictureInPictureAutomaticallyFromInline = NO;
    }
    [playerViewController.player play];

    [self presentViewController:playerViewController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSString *currentVideoFileName = filePathsVideoArray[indexPath.row];
    NSString *currentArtworkFileName = filePathsVideoArtworkArray[indexPath.row];

    UIAlertController *alertMenu = [UIAlertController alertControllerWithTitle:@"Options" message:nil preferredStyle:UIAlertControllerStyleAlert];

    [alertMenu addAction:[UIAlertAction actionWithTitle:@"Import Video To Camera Roll" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            NSURL *fileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:currentVideoFileName]];
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice" message:@"Video Saved To Camera Roll" preferredStyle:UIAlertControllerStyleAlert];
                                        
                    [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    }]];

                    [self presentViewController:alert animated:YES completion:nil];
                } else{
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice" message:@"Save To Camera Roll Failed \nMake Sure To Give Camera Roll Permission To YouTube In The iOS Settings App" preferredStyle:UIAlertControllerStyleAlert];
                                        
                    [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    }]];

                    [self presentViewController:alert animated:YES completion:nil];
                }
            });
        }];
    }]];

    [alertMenu addAction:[UIAlertAction actionWithTitle:@"Delete Video" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:currentVideoFileName] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:currentArtworkFileName] error:nil];

        UIAlertController *alertDeleted = [UIAlertController alertControllerWithTitle:@"Notice" message:@"Video Successfully Deleted" preferredStyle:UIAlertControllerStyleAlert];

        [alertDeleted addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [filePathsVideoArray removeAllObjects];
            [filePathsVideoArtworkArray removeAllObjects];
            [self setupVideoArrays];
            [self.tableView reloadData];
        }]];

        [self presentViewController:alertDeleted animated:YES completion:nil];
    }]];

    [alertMenu addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];

    [self presentViewController:alertMenu animated:YES completion:nil];
}

- (void)setupVideoArrays {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];

    NSArray *filePathsList = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory error:nil];
    filePathsVideoArray = [[NSMutableArray alloc] init];
    filePathsVideoArtworkArray = [[NSMutableArray alloc] init];
    for (id object in filePathsList) {
        if ([[object pathExtension] isEqualToString:@"mp4"]){
            [filePathsVideoArray addObject:object];
            NSString *cut = [object substringToIndex:[object length]-4];
            NSString *jpg = [NSString stringWithFormat:@"%@.jpg", cut];
            [filePathsVideoArtworkArray addObject:jpg];
        }
    }
}

- (void)coloursView {
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
        self.view.backgroundColor = [UIColor colorWithRed:0.949 green:0.949 blue:0.969 alpha:1.0];
    }
    else {
        self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self coloursView];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

@end
