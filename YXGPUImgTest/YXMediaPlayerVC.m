//
//  YXMediaPlayerVC.m
//  YXGPUImgTest
//
//  Created by ios on 2019/6/12.
//  Copyright © 2019 August. All rights reserved.
//

#import "YXMediaPlayerVC.h"

@interface YXMediaPlayerVC ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *sureBtn;

@end

@implementation YXMediaPlayerVC

- (void)dealloc {
    
    [self removeAVPlayerNoti];
    [self stopPlayer];
    self.player = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = self.view.bounds;
    
    [self.view.layer insertSublayer:playerLayer atIndex:0];
    [self begainPlayer];
    
    self.sureBtn.hidden = self.cancelBtn.hidden = NO;
}

/** 视屏播放内容 */
- (AVPlayerItem *)getAVPlayerItem {
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.videoURL];
    return playerItem;
}
/** 开始播放 */
- (void)begainPlayer {
    
//    CMTime time = CMTimeMakeWithSeconds(0, _player.currentItem.duration.timescale);
//    if (CMTIME_IS_INDEFINITE(time) || CMTIME_IS_INVALID(time)) {
//        return;
//    }
//    [self.player seekToTime:time];
    [self.player replaceCurrentItemWithPlayerItem:[self getAVPlayerItem]];
    [self addAVPlayerNoti:self.player.currentItem];
    if (self.player.rate == 0) {
        [self.player play];
    }
}
/** 停止播放 */
- (void)stopPlayer {
    
    if (self.player.rate == 1) {
        [self.player pause]; //如果在播放状态就停止
    }
}
/** 再次播放 */
- (void)playbackFinished:(NSNotification *)ntf {
    
    NSLog(@"视频播放完成");
    [self.player seekToTime:CMTimeMake(0, 1)];
    [self.player play];
}

#pragma mark - progress
/** 取消/移除储存视屏 */
- (void)progressCancelBtn {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.videoURL path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self.videoURL path] error:nil];
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}
/** 保存视频 */
- (void)progressSureBtn {
    
    [YXGPUImageUtils saveVideo:self.videoURL];
}

#pragma mark - 监听通知
/** 添加监听 */
- (void)addAVPlayerNoti:(AVPlayerItem *)playerItem {
    
    //监控状态属性
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}
/** 移除监听 */
- (void)removeAVPlayerNoti {
    
    AVPlayerItem *playerItem = self.player.currentItem;
    [playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
/**
 通过KVO监控播放器状态
 
 @param keyPath 监控属性
 @param object 监视器
 @param change 状态改变
 @param context 上下文
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if (status == AVPlayerStatusReadyToPlay) {
            NSLog(@"正在播放...，视频总长度:%.2f", CMTimeGetSeconds(playerItem.duration));
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue]; //本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds; //缓冲总长度
        NSLog(@"共缓冲：%.2f", totalBuffer);
    }
}

#pragma mark - setting
- (void)setVideoURL:(NSURL *)videoURL {
    
    _videoURL = videoURL;
}

#pragma mark - 懒加载
- (AVPlayer *)player {
    
    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:[self getAVPlayerItem]];
        [self addAVPlayerNoti:_player.currentItem];
    }
    return _player;
}
- (UIButton *)cancelBtn {
    
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _cancelBtn.bounds = CGRectMake(0, 0, 40, 40);
        _cancelBtn.center = CGPointMake(self.view.frame.size.width *0.5 - 100, self.view.frame.size.height - 120);
        [_cancelBtn setTitle:@"返回" forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(progressCancelBtn) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.cancelBtn];
    }
    return _cancelBtn;
}
- (UIButton *)sureBtn {
    
    if (!_sureBtn) {
        _sureBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _sureBtn.bounds = CGRectMake(0, 0, 40, 40);
        _sureBtn.center = CGPointMake(self.view.frame.size.width *0.5 + 100, self.view.frame.size.height - 120);
        [_sureBtn setTitle:@"确定" forState:UIControlStateNormal];
        [_sureBtn addTarget:self action:@selector(progressSureBtn) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.sureBtn];
    }
    return _sureBtn;
}

@end
