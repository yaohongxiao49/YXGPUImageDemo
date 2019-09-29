//
//  YXGPUImageUtils.h
//  YXGPUImgTest
//
//  Created by ios on 2019/6/12.
//  Copyright © 2019 August. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <cge/cge.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

extern const char * _Nonnull g_effectConfig[];
extern int g_configNum;

UIImage *loadImageCallback(const char *name, void *arg);
void loadImageOKCallback(UIImage *img, void *arg);

typedef void(^CompletionBlock)(NSURL *url, NSError *error);

@interface YXGPUImageUtils : NSObject

/**
 储存视频

 @param videoURL 视频地址
 */
+ (void)saveVideo:(NSURL *)videoURL;
/**
 储存图片

 @param image 图片
 */
+ (void)saveImage:(UIImage *)image;
/**
 储存图片

 @param image 图片
 @param completionBlock 回调
 */
+ (void)saveImage:(UIImage *)image completionBlock:(CompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
