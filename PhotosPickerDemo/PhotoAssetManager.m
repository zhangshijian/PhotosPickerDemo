//
//  PhotoAssetManager.m
//  PhotosPickerDemo
//
//  Created by 讯心科技 on 2017/10/26.
//  Copyright © 2017年 张诗健. All rights reserved.
//

#import "PhotoAssetManager.h"

@interface PhotoAssetManager ()

@property (nonatomic, strong) PHCachingImageManager *imageManager;

@property (nonatomic, assign) CGRect previousPreheatRect;

@property (nonatomic, strong) PHFetchResult<PHAsset *> *fetchResult;

@end



@implementation PhotoAssetManager

+ (instancetype)defaultManager
{
    static PhotoAssetManager *manager = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        manager = [[PhotoAssetManager alloc] init];
        
        manager.previousPreheatRect = CGRectZero;
    });
    
    return manager;
}


- (void)requestAuthorization:(void (^)(PHAuthorizationStatus))handler
{
    [PHPhotoLibrary requestAuthorization:handler];
}


- (PHFetchResult<PHAsset *> *)requestAllPhotoAssets
{
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    
    options.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES]];
    
    self.fetchResult = [PHAsset fetchAssetsWithOptions:options];
    
    return self.fetchResult;
}

- (void)requestThumbnailImageForAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage *, NSDictionary *))resultHandler
{
    [self.imageManager requestImageForAsset:asset targetSize:self.thumbnailSize contentMode:PHImageContentModeDefault options:nil resultHandler:resultHandler];
}

- (void)requestImageForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options resultHandler:(void (^)(UIImage *, NSDictionary *))resultHandler
{
    PHImageManager *manager = self.imageManager;
    
    [manager requestImageForAsset:asset targetSize:targetSize contentMode:contentMode options:options resultHandler:resultHandler];
}

- (void)updateCachedAssetsForCollectionView:(UICollectionView *)collectionView
{
    CGRect visibleRect = CGRectMake(collectionView.contentOffset.x, collectionView.contentOffset.y, collectionView.frame.size.width, collectionView.frame.size.height);
    
    CGRect preheatRect = CGRectInset(visibleRect, 0, -0.5 * visibleRect.size.height);
    
    CGFloat delta = fabs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    
    if (delta > collectionView.bounds.size.height / 3)
    {
        NSMutableArray *addedRects   = [[NSMutableArray alloc] init];
        NSMutableArray *removedRects = [[NSMutableArray alloc] init];
        
        if (CGRectGetMaxY(preheatRect) > CGRectGetMaxY(_previousPreheatRect))
        {
            [addedRects addObject:[NSValue valueWithCGRect:CGRectMake(preheatRect.origin.x, CGRectGetMaxY(_previousPreheatRect), preheatRect.size.width, CGRectGetMaxY(preheatRect) - CGRectGetMaxY(_previousPreheatRect))]];
        }
        
        if (CGRectGetMinY(_previousPreheatRect) > CGRectGetMinY(preheatRect))
        {
            [addedRects addObject:[NSValue valueWithCGRect:CGRectMake(preheatRect.origin.x, CGRectGetMinY(preheatRect), preheatRect.size.width, CGRectGetMinY(_previousPreheatRect) - CGRectGetMinY(preheatRect))]];
        }
        
        if (CGRectGetMaxY(preheatRect) < CGRectGetMinY(_previousPreheatRect))
        {
            [removedRects addObject:[NSValue valueWithCGRect:CGRectMake(preheatRect.origin.x, CGRectGetMaxY(preheatRect), preheatRect.size.width, CGRectGetMaxY(_previousPreheatRect) - CGRectGetMaxY(preheatRect))]];
        }
        
        if (CGRectGetMinY(_previousPreheatRect) - CGRectGetMinY(preheatRect))
        {
            [removedRects addObject:[NSValue valueWithCGRect:CGRectMake(preheatRect.origin.x, CGRectGetMinY(_previousPreheatRect), preheatRect.size.width, CGRectGetMinY(preheatRect) - CGRectGetMinY(_previousPreheatRect))]];
        }
        
        NSMutableArray *addedAssets = [[NSMutableArray alloc] init];
        
        for (NSValue *value in addedRects)
        {
            CGRect rect = [value CGRectValue];
            
            NSArray *attributesArray = [collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
            
            for (UICollectionViewLayoutAttributes * attributes in attributesArray)
            {
                PHAsset *asset = [self.fetchResult objectAtIndex:attributes.indexPath.item];
                
                [addedAssets addObject:asset];
            }
        }
        
        NSMutableArray *removedAssets = [[NSMutableArray alloc] init];
        
        for (NSValue *value in removedRects)
        {
            CGRect rect = [value CGRectValue];
            
            NSArray *attributesArray = [collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
            
            for (UICollectionViewLayoutAttributes * attributes in attributesArray)
            {
                PHAsset *asset = [self.fetchResult objectAtIndex:attributes.indexPath.item];
                
                [removedAssets addObject:asset];
            }
        }
        
        [self.imageManager startCachingImagesForAssets:addedAssets targetSize:self.thumbnailSize contentMode:PHImageContentModeAspectFill options:nil];
        
        [self.imageManager stopCachingImagesForAssets:removedAssets targetSize:self.thumbnailSize contentMode:PHImageContentModeAspectFill options:nil];
        
        self.previousPreheatRect = preheatRect;
    }
}

- (void)resetCachedAssets
{
    [self.imageManager stopCachingImagesForAllAssets];
    
    self.previousPreheatRect = CGRectZero;
}

- (void)differencesBetweenOldRect:(CGRect)oldRect andNewRect:(CGRect)newRect addedRectArr:(NSMutableArray *)addedRectArr removedRectArr:(NSMutableArray *)removedRectArr
{
    if (CGRectIntersectsRect(oldRect, newRect))
    {
        if (CGRectGetMaxY(newRect) > CGRectGetMaxY(oldRect))
        {
            [addedRectArr addObject:[NSValue valueWithCGRect:CGRectMake(newRect.origin.x, CGRectGetMaxY(oldRect), newRect.size.width, CGRectGetMaxY(newRect) - CGRectGetMaxY(oldRect))]];
        }
        
        if (CGRectGetMinY(oldRect) > CGRectGetMinY(newRect))
        {
            [addedRectArr addObject:[NSValue valueWithCGRect:CGRectMake(newRect.origin.x, CGRectGetMinY(newRect), newRect.size.width, CGRectGetMinY(oldRect) - CGRectGetMinY(newRect))]];
        }
        
        if (CGRectGetMaxY(newRect) < CGRectGetMaxY(oldRect))
        {
            [removedRectArr addObject:[NSValue valueWithCGRect:CGRectMake(newRect.origin.x, CGRectGetMaxY(newRect), newRect.size.width, CGRectGetMaxY(oldRect) - CGRectGetMaxY(newRect))]];
        }
        
        if (CGRectGetMinY(oldRect) < CGRectGetMinY(newRect))
        {
            [removedRectArr addObject:[NSValue valueWithCGRect:CGRectMake(newRect.origin.x, CGRectGetMinY(oldRect), newRect.size.width, CGRectGetMinY(newRect) - CGRectGetMinY(oldRect))]];
        }
    }else
    {
        [addedRectArr addObject:[NSValue valueWithCGRect:newRect]];
        
        [removedRectArr addObject:[NSValue valueWithCGRect:oldRect]];
    }
}

#pragma mark- getter
- (PHCachingImageManager *)imageManager
{
    return (PHCachingImageManager *)[PHCachingImageManager defaultManager];
}

@end

