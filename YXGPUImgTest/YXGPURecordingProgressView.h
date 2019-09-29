//
//  YXGPURecordingProgressView.h
//  YXGPUImgTest
//
//  Created by ios on 2019/6/12.
//  Copyright © 2019 August. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YXRecordingEnthusiasmType) {
    /** 主动 */
    YXRecordingEnthusiasmTypeActive,
    /** 被动 */
    YXRecordingEnthusiasmTypePassive,
};

typedef void(^YXGPURecordingProgressBlock)(CGFloat current);

@interface YXGPURecordingProgressView : UIView

/**
 初始化进度条，设置进度完成时间maxTime，返回当前时间
 
 @param maxTime 设置进度完成时间
 @param circleSize 圆心框的尺寸
 @param callBackCurrentProcessTime 返回当前时间
 @return LZBCircleProcessView
 */
- (instancetype)initWithMaxTime:(CGFloat)maxTime circleSize:(CGSize)circleSize callBackCurrentProcessTime:(YXGPURecordingProgressBlock)callBackCurrentProcessTime;

/** 开始动画 */
- (void)startAnimation;

/** 停止动画 */
- (void)stopAnimation:(YXRecordingEnthusiasmType)type;

@property (nonatomic, copy) YXGPURecordingProgressBlock yxGPURecordingProgressBlock;

/** 毛玻璃效果 */
@property (nonatomic, strong) UIVisualEffectView *visualEffectView;

@end

NS_ASSUME_NONNULL_END
