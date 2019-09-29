//
//  ViewController.m
//  YXGPUImgTest
//
//  Created by ios on 2019/6/10.
//  Copyright © 2019 August. All rights reserved.
//

#import "ViewController.h"
#import <cge/cge.h>
#import "YXGPUImageUtils.h"
#import "YXGPURecordingProgressView.h"
#import "YXMediaPlayerVC.h"
#import "YXGPUImageUtils.h"

#define RECORD_WIDTH 480
#define RECORD_HEIGHT 640
#define _MYAVCaptureSessionPreset(w, h) AVCaptureSessionPreset ## w ## x ## h
#define MYAVCaptureSessionPreset(w, h) _MYAVCaptureSessionPreset(w, h)

@interface ViewController ()

@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *changeDirection;
@property (nonatomic, strong) UIButton *skinCareBtn;
@property (nonatomic, strong) UIButton *currenBtn;
@property (nonatomic, strong) UIButton *flashBtn;

@property CGECameraViewHandler *myCameraViewHandler;
@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) NSURL *movieURL;
@property (nonatomic) int currentFilterIndex;

@property (nonatomic, strong) YXGPURecordingProgressView *recordingProgressView;
@property (nonatomic, assign) NSInteger movieNum;
@property (nonatomic, strong) NSMutableArray *moviePathArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initVideoView];
    self.backBtn.hidden = self.changeDirection.hidden = self.skinCareBtn.hidden = self.recordingProgressView.hidden = self.flashBtn.hidden = NO;
}

- (void)initVideoView {
    
    CGRect rt = [[UIScreen mainScreen] bounds];
    
#if SHOW_FULLSCREEN
    _glkView = [[GLKView alloc] initWithFrame:rt];
#else
    _glkView = [[GLKView alloc] initWithFrame:self.view.frame];
#endif
    
    _myCameraViewHandler = [[CGECameraViewHandler alloc] initWithGLKView:_glkView];
    
//    AVCaptureSessionPreset640x480
    if ([_myCameraViewHandler setupCamera:MYAVCaptureSessionPreset(RECORD_HEIGHT, RECORD_WIDTH) cameraPosition:AVCaptureDevicePositionFront isFrontCameraMirrored:YES authorizationFailed:^{}]) {
        
        [[_myCameraViewHandler cameraDevice] startCameraCapture];
    }
    
    [self.view addSubview:_glkView];
    
    CGRect scrollRT = rt;
    scrollRT.origin.y = scrollRT.size.height - 60;
    scrollRT.size.height = 50;
    UIScrollView *myScrollView = [[UIScrollView alloc] initWithFrame:scrollRT];
    
    CGRect frame = CGRectMake(0, 0, 95, 50);
    
    frame.size.width = 70;
    for (int i = 0; i != g_configNum; ++i) {
        UIButton *btn = [[UIButton alloc] initWithFrame:frame];
        frame.origin.x += frame.size.width;
        
        if (i == 0) {
            [btn setTitle:@"原图" forState:UIControlStateNormal];
        }
        else {
            [btn setTitle:[NSString stringWithFormat:@"滤镜0%d", i] forState:UIControlStateNormal];
        }
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateDisabled];
        [btn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [btn.layer setBorderColor:[UIColor blueColor].CGColor];
        [btn.layer setBorderWidth:1.5f];
        [btn.layer setCornerRadius:10.0f];
        btn.tag = i;
        [btn addTarget:self action:@selector(filterButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [myScrollView addSubview:btn];
    }
    
    myScrollView.contentSize = CGSizeMake(frame.origin.x, 50);
    [self.view addSubview:myScrollView];
    
    [CGESharedGLContext globalSyncProcessingQueue:^{
        
        [CGESharedGLContext useGlobalGLContext];
        void cgePrintGLInfo(void);
        cgePrintGLInfo();
    }];
    
    [_myCameraViewHandler fitViewSizeKeepRatio:YES];
    
    [[_myCameraViewHandler cameraRecorder] setPictureHighResolution:YES];
    [_myCameraViewHandler setFilterIntensity:0.5];
    cgeSetLoadImageCallback(loadImageCallback, loadImageOKCallback, nil);
    
    _moviePathArr = [[NSMutableArray alloc] init];
}
/** 更改锚点、对焦 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    __weak typeof(self) weakSelf = self;
    if ([[touches anyObject] view] != self.recordingProgressView.visualEffectView) {
        [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
            
            CGPoint touchPoint = [touch locationInView:weakSelf.glkView];
            CGSize sz = [weakSelf.glkView frame].size;
            CGPoint transPoint = CGPointMake(touchPoint.x /sz.width, touchPoint.y /sz.height);
            
            [weakSelf.myCameraViewHandler focusPoint:transPoint];
        }];
    }
}

#pragma mark - progress
/** 返回 */
- (void)progressBackBtn {
    
    [[[_myCameraViewHandler cameraRecorder] cameraDevice] stopCameraCapture];

    [_myCameraViewHandler clear];
    _myCameraViewHandler = nil;
    [CGESharedGLContext clearGlobalGLContext];
}
/** 切换摄像头 */
- (void)progressChangeDirection {
    
    [_myCameraViewHandler switchCamera:YES];
    
    CMVideoDimensions dim = [[[_myCameraViewHandler cameraDevice] inputCamera] activeFormat].highResolutionStillImageDimensions;
    NSLog(@"Max Photo Resolution: %d, %d\n", dim.width, dim.height);
}
/** 一键美颜 */
- (void)progressSkinCareBtn {
    
    if ([_myCameraViewHandler isGlobalFilterEnabled]) {
        [_myCameraViewHandler enableFaceBeautify:NO];
        [_skinCareBtn setTitle:@"开启美颜" forState:UIControlStateNormal];
    }
    else {
        [_myCameraViewHandler enableFaceBeautify:YES];
        [_skinCareBtn setTitle:@"关闭美颜" forState:UIControlStateNormal];
    }
}
/** 闪光灯 */
- (void)progressFlashBtn {
    
    static AVCaptureFlashMode flashLightList[] = {
        AVCaptureFlashModeOff,
        AVCaptureFlashModeOn,
        AVCaptureFlashModeAuto
    };
    static int flashLightIndex = 0;
    
    ++flashLightIndex;
    flashLightIndex %= sizeof(flashLightList) /sizeof(*flashLightList);
    
    [_myCameraViewHandler setCameraFlashMode:flashLightList[flashLightIndex]];
}
/** 切换滤镜 */
- (void)filterButtonClicked:(UIButton *)sender {
    
    sender.enabled =! sender.enabled;
    
    self.currenBtn.enabled = YES;
    self.currenBtn = sender;
    
    _currentFilterIndex = (int)sender.tag;
    
    const char *config = g_effectConfig[_currentFilterIndex];
    [_myCameraViewHandler setFilterWithConfig:config];
}
/** 保存图片 */
- (void)saveImg {
    
    //美颜图片
    [_myCameraViewHandler takeShot:^(UIImage *image) {
        
        if(image != nil) {
            [YXGPUImageUtils saveImage:image];
        }
    }];
}
/** 输入/输出数据流 */
- (void)beginOrEndRecord {
    
    __weak typeof(self) weakSelf = self;
    if([_myCameraViewHandler isRecording]) {
        void (^finishBlock)(void) = ^{
            
            [CGESharedGLContext mainASyncProcessingQueue:^{
                
                [weakSelf.moviePathArr addObject:weakSelf.movieURL];
            }];
        };
        [_myCameraViewHandler endRecording:finishBlock withCompressionLevel:0];
    }
    else {
        _movieNum ++;
        
        _movieURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"movie0%@.mp4", @(_movieNum)]]];
        unlink([_movieURL.path UTF8String]);
        [_myCameraViewHandler startRecording:_movieURL size:CGSizeMake(RECORD_WIDTH, RECORD_HEIGHT)];
    }
}
/** 预览视图 */
- (void)gotoPlayer {
    
    YXMediaPlayerVC *player = [[YXMediaPlayerVC alloc] init];
    player.videoURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"merge.mp4"]]];;
    player.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:player animated:NO completion:nil];
}
/** 合并视频 */
- (void)mergeMovie {
    
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVMutableComposition *composition = [AVMutableComposition composition];
    //为视频类型的的Track
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //只合并视频，导出后声音会消失，所以需要把声音插入到混淆器中
    //添加音频,添加本地其他音乐也可以,与视频一致
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSArray *reversedArray = [[(NSArray *)_moviePathArr reverseObjectEnumerator] allObjects];
    for (NSURL *url in reversedArray) {
        
        AVAsset *asset = [[AVURLAsset alloc] initWithURL:url options:optDict];
        //由于没有计算当前CMTime的起始位置，现在插入0的位置,所以合并出来的视频是后添加在前面，可以计算一下时间，插入到指定位置
        //CMTimeRangeMake 指定起去始位置
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
        [compositionTrack insertTimeRange:timeRange ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:nil];
        
        [audioTrack insertTimeRange:timeRange ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio][0] atTime:kCMTimeZero error:nil];
    }
    NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"merge.mp4"];
    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    exporterSession.outputFileType = AVFileTypeMPEG4;
    exporterSession.outputURL = [NSURL fileURLWithPath:filePath]; //如果文件已存在，将造成导出失败
    exporterSession.shouldOptimizeForNetworkUse = YES; //用于互联网传输
    [exporterSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exporterSession.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"exporter Unknow");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"exporter Failed");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporter Completed");
                [self gotoPlayer];
                break;
        }
    }];
}

#pragma mark - GestureRecognizer
- (void)recordingProgressViewTouch:(UIGestureRecognizer *)gesture {
    
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
        
        [self saveImg];
    }
    else {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            [self.recordingProgressView startAnimation];
            [self beginOrEndRecord];
        }
        else if (gesture.state == UIGestureRecognizerStateEnded) {
            
            [self.recordingProgressView stopAnimation:YXRecordingEnthusiasmTypeActive];
        }
    }
}

#pragma mark - 懒加载
- (UIButton *)backBtn {
    
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _backBtn.frame = CGRectMake(20, 40, 20, 20);
        [_backBtn setTitle:@"返回" forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(progressBackBtn) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_backBtn];
    }
    return _backBtn;
}
- (UIButton *)changeDirection {
    
    if (!_changeDirection) {
        _changeDirection = [UIButton buttonWithType:UIButtonTypeSystem];
        _changeDirection.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 100, 40, 80, 30);
        [_changeDirection setTitle:@"切换摄像头" forState:UIControlStateNormal];
        [_changeDirection addTarget:self action:@selector(progressChangeDirection) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_changeDirection];
    }
    return _changeDirection;
}
- (UIButton *)skinCareBtn {
    
    if (!_skinCareBtn) {
        _skinCareBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _skinCareBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 100, 80, 80, 30);
        [_skinCareBtn setTitle:@"开启美颜" forState:UIControlStateNormal];
        [_skinCareBtn addTarget:self action:@selector(progressSkinCareBtn) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_skinCareBtn];
    }
    return _skinCareBtn;
}
- (UIButton *)flashBtn {
    
    if (!_flashBtn) {
        _flashBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _flashBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 100, 130, 80, 30);
        [_flashBtn setTitle:@"开启闪光" forState:UIControlStateNormal];
        [_flashBtn addTarget:self action:@selector(progressFlashBtn) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_flashBtn];
    }
    return _flashBtn;
}
- (YXGPURecordingProgressView *)recordingProgressView {
    
    if(!_recordingProgressView) {
        __weak typeof(self) weakSelf = self;
        _recordingProgressView = [[YXGPURecordingProgressView alloc] initWithMaxTime:15 circleSize:CGSizeMake(92, 92) callBackCurrentProcessTime:^(CGFloat current) {
            
            [weakSelf beginOrEndRecord];
        }];
        _recordingProgressView.bounds = CGRectMake(0, 0, 92, 92);
        _recordingProgressView.center = CGPointMake(self.view.frame.size.width *0.5, self.view.frame.size.height - 140);
        [self.view addSubview:_recordingProgressView];
        [_recordingProgressView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recordingProgressViewTouch:)]];
        [_recordingProgressView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(recordingProgressViewTouch:)]];
    }
    return _recordingProgressView;
}

@end
