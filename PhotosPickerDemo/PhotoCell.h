//
//  PhotoCell.h
//  PhotosPickerDemo
//
//  Created by 张诗健 on 2017/10/25.
//  Copyright © 2017年 张诗健. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCell : UICollectionViewCell

@property (strong, nonatomic) UIImageView *imageView;

@end



@interface PhotoPickerCell : PhotoCell

- (void)didTouchSelectedButtonBlock:(void (^)(BOOL selected, PhotoPickerCell *cell))block;

@end
