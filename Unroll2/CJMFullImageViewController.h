//
//  CJMFullImageViewController.h
//  Unroll
//
//  Created by Curt on 4/24/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CJMPhotoAlbum;
@class CJMFullImageViewController;

@protocol CJMFullImageViewControllerDelegate <NSObject>

- (void)toggleFullImageShowForViewController:(CJMFullImageViewController *)viewController;
- (void)viewController:(CJMFullImageViewController *)currentVC deletedImageAtIndex:(NSInteger)imageIndex;

@end

@interface CJMFullImageViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) NSString *albumName;
@property (nonatomic) NSInteger index;
@property (nonatomic, weak) id <CJMFullImageViewControllerDelegate> delegate;
@property (nonatomic) BOOL viewsVisible;

- (void)showPopUpMenu;
- (void)confirmImageDelete;

@end
