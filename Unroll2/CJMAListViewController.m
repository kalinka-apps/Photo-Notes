//
//  CJMAListViewController.m
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMAListViewController.h"
#import "CJMGalleryViewController.h"
#import "CJMAListTableViewCell.h"
#import "CJMAlbumManager.h"
#import "CJMPhotoAlbum.h"
#import "CJMServices.h"

#define CJMAListCellIdentifier @"AlbumCell"

@interface CJMAListViewController () 

@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;

@end

@implementation CJMAListViewController

#pragma mark - view prep and display

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"CJMAListTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CJMAListCellIdentifier];
    
    self.tableView.rowHeight = 80;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self noAlbumsPopUp];
}


- (void)noAlbumsPopUp
{//If there are no albums, prompt the user to create one after a delay.
    dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    if ([[CJMAlbumManager sharedInstance] allAlbums].count == 0) {
        dispatch_after(waitTime, dispatch_get_main_queue(), ^{
            [self.navigationItem setPrompt:@"Tap + below to create a new Photo Notes album!"];
        });
    } else {
        [self.navigationItem setPrompt:nil];
    }
}

#pragma mark - tableView data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[CJMAlbumManager sharedInstance] allAlbums].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CJMAListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CJMAListCellIdentifier forIndexPath:indexPath];
    
    CJMPhotoAlbum *album = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
    [self configureTextForCell:cell withAlbum:album];
    [self configureThumbnailForCell:cell forAlbum:album];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    cell.showsReorderControl = YES;
    
    return cell;
}

- (void)configureTextForCell:(CJMAListTableViewCell *)cell withAlbum:(CJMPhotoAlbum *)album
{
    cell.cellAlbumName.text = album.albumTitle;
    
    if (album.albumPhotos.count == 0) {
        cell.cellAlbumCount.text = @"No Photos";
    } else {
        cell.cellAlbumCount.text = [NSString stringWithFormat:@"%lu Photos", (unsigned long)album.albumPhotos.count];
    }
}

- (void)configureThumbnailForCell:(CJMAListTableViewCell *)cell forAlbum:(CJMPhotoAlbum *)album
{
    [[CJMServices sharedInstance] fetchThumbnailForImage:album.albumPreviewImage
                                                 handler:^(UIImage *thumbnail) {
                                                     cell.cellThumbnail.image = thumbnail;
                                                 }];
    if (cell.cellThumbnail.image == nil) {
        if (album.albumPhotos.count >= 1) {
            CJMImage *firstImage = album.albumPhotos[0];
            [[CJMServices sharedInstance] fetchThumbnailForImage:firstImage handler:^(UIImage *thumbnail) {
                cell.cellThumbnail.image = thumbnail;
            }];
        } else {
            cell.cellThumbnail.image = [UIImage imageNamed:@"no_image.jpg"];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{//replaces blank rows with blank space in the tableView
    UIView *view = [[UIView alloc] init];
    return view;
}

#pragma mark - tableView delegate methods

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"EditAlbum" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"ViewGallery" sender:[tableView cellForRowAtIndexPath:indexPath]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Editing the list

- (IBAction)editTableView:(id)sender
{
    if ([self.editButton.title isEqual:@"Edit"]) {
        [self.editButton setTitle:@"Done"];
        [self.tableView setEditing:YES animated:YES];
    } else {
        [self.editButton setTitle:@"Edit"];
        [self.tableView setEditing:NO animated:YES];
        
        [[CJMAlbumManager sharedInstance] save];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[CJMAlbumManager sharedInstance] removeAlbumAtIndex:indexPath.row];
    [[CJMAlbumManager sharedInstance] save];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self noAlbumsPopUp];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [[CJMAlbumManager sharedInstance] replaceAlbumAtIndex:toIndexPath.row withAlbumFromIndex:fromIndexPath.row];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ViewGallery"]) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        CJMPhotoAlbum *sentAlbum = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
        CJMGalleryViewController *galleryVC = (CJMGalleryViewController *)segue.destinationViewController;
        galleryVC.album = sentAlbum;
        
    } else if ([segue.identifier isEqualToString:@"EditAlbum"]) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        CJMPhotoAlbum *sentAlbum = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
        UINavigationController *navigationController = segue.destinationViewController;
        CJMADetailViewController *detailVC = (CJMADetailViewController *)navigationController.viewControllers[0];
        detailVC.albumToEdit = sentAlbum;
        detailVC.title = @"Album Info";
        detailVC.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"AddAlbum"]) {
        
        UINavigationController *navigationController = segue.destinationViewController;
        CJMADetailViewController *detailVC = navigationController.viewControllers[0];
        detailVC.title = @"Create Album";
        detailVC.delegate = self;
    }
}

#pragma mark - DetailVC delegate methods

- (void)albumDetailViewControllerDidCancel:(CJMADetailViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)albumDetailViewController:(CJMADetailViewController *)controller didFinishAddingAlbum:(CJMPhotoAlbum *)album
{
    NSInteger newRowIndex = [[[CJMAlbumManager sharedInstance] allAlbums] count];
    
    [[CJMAlbumManager sharedInstance] addAlbum:album];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newRowIndex inSection:0];
    NSArray *indexPaths = @[indexPath];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [[CJMAlbumManager sharedInstance] save];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)albumDetailViewController:(CJMADetailViewController *)controller didFinishEditingAlbum:(CJMPhotoAlbum *)album
{
    [self.tableView reloadData];
    [[CJMAlbumManager sharedInstance] save];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
