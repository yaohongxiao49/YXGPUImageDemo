//
//  YXGPURecordingProgressView.m
//  YXGPUImgTest
//
//  Created by ios on 2019/6/12.
//  Copyright © 2019 August. All rights reserved.
//

#import "YXGPURecordingProgressView.h"

#define YXCircleProcessWidth 6.0f
#define YXCircleProcessTimeMargin 0.1
#define YXCircleProcessDefaultMargin 20

#define YXColorRGB(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

@interface YXGPURecordingProgressView ()

/** 包围圈 */
@property (nonatomic, strong) CAShapeLayer *circleLayer;
/** 进度条 */
@property (nonatomic, strong) CAShapeLayer *processLayer;
@property (nonatomic, assign) CGSize circleSize;
/** 中心点 */
@property (nonatomic, strong) UIImageView *centerView;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat timeCount;
@property (nonatomic, assign) CGFloat maxTime;

@end

@implementation YXGPURecordingProgressView

- (instancetype)initWithMaxTime:(CGFloat)maxTime circleSize:(CGSize)circleSize callBackCurrentProcessTime:(YXGPURecordingProgressBlock)callBackCurrentProcessTime {
    self = [super init];
    
    if (self) {
        self.circleSize = circleSize;
        self.yxGPURecordingProgressBlock = callBackCurrentProcessTime;
        if (maxTime == 0) {
            maxTime = 15.0;
        }
        self.maxTime = maxTime;
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.visualEffectView.frame = self.layer.bounds;
    self.circleLayer.frame = self.layer.bounds;
    self.processLayer.frame = CGRectMake(YXCircleProcessWidth / 2, YXCircleProcessWidth / 2, self.circleSize.width - YXCircleProcessWidth, self.circleSize.height - YXCircleProcessWidth);
    self.centerView.center = CGPointMake(self.circleSize.width /2, self.circleSize.height /2);
}


#pragma mark - handel
/** 开始动画 */
- (void)startAnimation {
    
    self.timeCount = 0;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:1.0 animations:^{
        
        weakSelf.transform = CGAffineTransformScale(weakSelf.transform, 1.2, 1.2);
        weakSelf.centerView.transform = CGAffineTransformScale(weakSelf.centerView.transform, 0.8, 0.8);
    }];
    [self startTimer];
}
/** 停止动画 */
- (void)stopAnimation:(YXRecordingEnthusiasmType)type {
    
    switch (type) {
        case YXRecordingEnthusiasmTypeActive: {
            if (self.timeCount < self.maxTime && self.timeCount != 0) {
                if (self.yxGPURecordingProgressBlock) {
                    self.yxGPURecordingProgressBlock(self.timeCount);
                }
            }
            break;
        }
        case YXRecordingEnthusiasmTypePassive: {
            if (self.yxGPURecordingProgressBlock) {
                self.yxGPURecordingProgressBlock(self.timeCount);
            }
            break;
        }
        default:
            break;
    }
    
    [self stopTimer];
    self.transform = CGAffineTransformIdentity;
    self.centerView.transform = CGAffineTransformIdentity;
    self.processLayer.strokeEnd = 0;
}

- (void)updateProcess {
    
    self.timeCount += YXCircleProcessTimeMargin;
    self.processLayer.strokeEnd += YXCircleProcessTimeMargin /self.maxTime;
    
    if (self.timeCount >= self.maxTime) {
        [self stopAnimation:YXRecordingEnthusiasmTypePassive];
    }
}
- (void)startTimer {
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:YXCircleProcessTimeMargin target:self selector:@selector(updateProcess) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}
- (void)stopTimer {
    
    [self.timer invalidate];
    self.timer = nil;
    self.timeCount = 0;
}

#pragma mark - 懒加载
- (UIVisualEffectView *)visualEffectView {
    
    if (!_visualEffectView) {
        //实现模糊效果
        UIBlurEffect *blurEffrct = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        //毛玻璃视图
        _visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffrct];
        _visualEffectView.alpha = 0.8;
        _visualEffectView.layer.masksToBounds = YES;
        _visualEffectView.layer.cornerRadius = self.circleSize.width /2;
        [self insertSubview:_visualEffectView atIndex:0];
    }
    return _visualEffectView;
}
- (CAShapeLayer *)circleLayer {
    
    if (!_circleLayer) {
        _circleLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.circleSize.width /2, self.circleSize.height /2) radius:self.circleSize.width /2 startAngle:0 endAngle:2 *M_PI clockwise:YES];
        _circleLayer.path = path.CGPath;
        _circleLayer.lineWidth = YXCircleProcessWidth;
        _circleLayer.fillColor = nil;
        _circleLayer.strokeColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:self.circleLayer];
    }
    return _circleLayer;
}
- (CAShapeLayer *)processLayer {
    
    if (!_processLayer) {
        _processLayer = [CAShapeLayer layer];
        _processLayer.fillColor = nil;
        _processLayer.lineWidth = YXCircleProcessWidth;
        _processLayer.strokeColor = YXColorRGB(255, 194, 52).CGColor;
        _processLayer.strokeStart = 0;
        _processLayer.strokeEnd = 0;
        _processLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.circleSize.width - YXCircleProcessWidth, self.circleSize.height - YXCircleProcessWidth) cornerRadius:(self.circleSize.width - YXCircleProcessWidth) /2].CGPath;
        [self.layer addSublayer:self.processLayer];
    }
    return _processLayer;
}
- (UIImageView *)centerView {
    
    if (!_centerView) {
        _centerView = [UIImageView new];
        _centerView.bounds = CGRectMake(0, 0, self.circleSize.width - YXCircleProcessDefaultMargin, self.circleSize.height - YXCircleProcessDefaultMargin);
        _centerView.backgroundColor = [UIColor whiteColor];
        _centerView.layer.cornerRadius = (self.circleSize.width - YXCircleProcessDefaultMargin) *0.5;
        _centerView.layer.masksToBounds = YES;
        [self addSubview:self.centerView];
    }
    return _centerView;
}

@end
