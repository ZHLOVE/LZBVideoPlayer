//
//  LZBVideoPlayerView.m
//  LZBVideoPlayer
//
//  Created by zibin on 2017/7/27.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBVideoPlayerView.h"
#import "LZBVideoPlayer.h"
#import "LZBPlayerBottomControlView.h"


@interface LZBVideoPlayerView() <LZBVideoPlayerDelegate>

@property (nonatomic, strong) LZBPlayerBottomControlView *bottomControllView; //底部控制操作View

@property (nonatomic, strong) NSTimer *timer;  //定时刷新UI

@property (nonatomic, assign) BOOL isAlreadyAdd;  //是不是早就已经增加播放层

@property (nonatomic, strong) NSURL *currentURL;


@end

@implementation LZBVideoPlayerView
- (instancetype)init
{
  if(self = [super init])
  {
      self.backgroundColor = [UIColor blackColor];
      self.isAlreadyAdd = NO;
      [self addSubview:self.bottomControllView];
      [self startTimer]; 
  }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat currentPlayerLayerHeight = self.bounds.size.height - [LZBPlayerBottomControlView getPlayerBottomHeight];
    self.bottomControllView.frame = CGRectMake(0, currentPlayerLayerHeight, self.bounds.size.width, [LZBPlayerBottomControlView getPlayerBottomHeight]);
    
    AVPlayerLayer *playerLayer = [LZBVideoPlayer shareInstance].currentPlayerLayer;
    
    if(playerLayer != nil)
    {
        playerLayer.frame = CGRectMake(0, 0, self.bounds.size.width, currentPlayerLayerHeight);
    }
    
    if(self.loadingView != nil)
    {
        self.loadingView.center = CGPointMake(self.bounds.size.width * 0.5, currentPlayerLayerHeight * 0.5);
        self.loadingView.bounds = self.loadingView.bounds;
    }
   
}

- (void)playWithURL:(NSURL *)url  isSupportCache:(BOOL)isSupportCache
{
    self.currentURL = url;
    [[LZBVideoPlayer shareInstance] playWithURL:url isSupportCache:isSupportCache];
    [LZBVideoPlayer shareInstance].delegate = self;
    [self addLoadAnimation];
}



#pragma mark-LZBVideoPlayerDelegate
- (void)videoPlayer:(LZBVideoPlayer *)player didStateChange:(LZBVideoPlayerState)state
{
    switch (state) {
        case LZBVideoPlayerState_ReadyToPlay:
            {
                [self addPlayLayerToSuperView];
            }
            break;
        case LZBVideoPlayerState_Playing:
            {
                [self hiddenLoadAnimation];
            }
            break;
        case LZBVideoPlayerState_Stoped:
        case LZBVideoPlayerState_Pause:
        case LZBVideoPlayerState_Failed:
        case LZBVideoPlayerState_Loading:
            {
                [self showLoadAnimaion];
            }
            break;
        default:
            break;
    }
}

#pragma mark - 加载动画
- (void)addLoadAnimation
{
    if(self.loadingView == nil)
    {
        UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
        self.loadingView = loading;
#pragma clang diagnostic pop
    }
    if(self.loadingView.superview == nil)
    {
        [self addSubview:self.loadingView];
    }
    [self showLoadAnimaion];
}

- (void)showLoadAnimaion
{
    if ([self.loadingView respondsToSelector:@selector(startAnimating)]) {
        [self.loadingView performSelector:@selector(startAnimating)];
    }
    self.loadingView.hidden = NO;
}

- (void)hiddenLoadAnimation
{
    if ([self.loadingView respondsToSelector:@selector(stopAnimating)]) {
        [self.loadingView performSelector:@selector(stopAnimating)];
    }
    self.loadingView.hidden = YES;
}

- (void)removeLoadAnimation
{
    [self hiddenLoadAnimation];
    [self.loadingView removeFromSuperview];
}


#pragma mark - 事件处理
- (void)sliderValueChange:(UISlider *)slider
{
    [[LZBVideoPlayer shareInstance] seekWithProgress:slider.value];
}

- (void)lastButtonClick:(UIButton *)lastButton
{
    NSInteger index = [self.playAddresses indexOfObject:self.currentURL];
    if(index == 0)
    {
        NSLog(@"已经是第一个视频");
        return;
    }
    index--;
    NSURL *url = self.playAddresses[index];
    [[LZBVideoPlayer shareInstance] playWithURL:url isSupportCache:YES];
    self.currentURL = url;
    
}

- (void)nextButtonClick:(UIButton *)nextButton{
    NSInteger index = [self.playAddresses indexOfObject:self.currentURL];
    if(index == self.playAddresses.count - 1)
    {
        NSLog(@"已经是第最后个视频");
        return;
    }
    index++;
    NSURL *url = self.playAddresses[index];
    [[LZBVideoPlayer shareInstance] playWithURL:url isSupportCache:YES];
    self.currentURL = url;
}

- (void)playPasueButtonClick:(UIButton *)playPauseButton
{
    playPauseButton.selected = !playPauseButton.isSelected;
    if(playPauseButton.selected)
    {
        [[LZBVideoPlayer shareInstance] pause];
        NSLog(@"UI是播放中状态");
    }
    
    else
    {
      [[LZBVideoPlayer shareInstance] resume];
         NSLog(@"UI是暂停状态");
    }
    
    
    
}


#pragma mark - UI -Handle
//增加显示层到父类
- (void)addPlayLayerToSuperView
{

    AVPlayerLayer *playerLayer = [LZBVideoPlayer shareInstance].currentPlayerLayer;
    if(playerLayer != nil)
    {
        [self.layer insertSublayer:playerLayer atIndex:0];
        [self setNeedsLayout];
        self.isAlreadyAdd = YES;
    }
}

//更新当前时间
- (void)updateCurrentTimeLabel:(CGFloat)currentTime
{
    long videoCurrentTime = ceil(currentTime);
    
    NSString *currentStr = nil;
    if (videoCurrentTime < 3600) {
        currentStr =  [NSString stringWithFormat:@"%02li:%02li",lround(floor(videoCurrentTime/60.f)),lround(floor(videoCurrentTime/1.f))%60];
    } else {
        currentStr =  [NSString stringWithFormat:@"%02li:%02li:%02li",lround(floor(videoCurrentTime/3600.f)),lround(floor(videoCurrentTime%3600)/60.f),lround(floor(videoCurrentTime/1.f))%60];
    }
    self.bottomControllView.currentTimeLabel.text = currentStr;
    
}

//更新总共时间
- (void)updateTotalTimeLabel:(CGFloat)totalTime
{
    long videoTotalTime = ceil(totalTime);
    
    NSString *totalStr = nil;
    if (videoTotalTime < 3600) {
        totalStr =  [NSString stringWithFormat:@"%02li:%02li",lround(floor(videoTotalTime/60.f)),lround(floor(videoTotalTime/1.f))%60];
    } else {
        totalStr =  [NSString stringWithFormat:@"%02li:%02li:%02li",lround(floor(videoTotalTime/3600.f)),lround(floor(videoTotalTime%3600)/60.f),lround(floor(videoTotalTime/1.f))%60];
    }
    self.bottomControllView.totalTimeLabel.text = totalStr;
}

//更新滑块的进度
- (void)updateSlideValue:(CGFloat)value
{
    self.bottomControllView.slider.value = value;
}


#pragma mark - 定时器刷新UI
- (void)startTimer
{
    self.timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)updateUI
{
    //更新UI
    [self updateCurrentTimeLabel:[LZBVideoPlayer shareInstance].currentTime];  //当前时间
    [self updateTotalTimeLabel:[LZBVideoPlayer shareInstance].totalTime]; //当前总时间
    [self.bottomControllView.progressView setProgress:[LZBVideoPlayer shareInstance].loadedProgress animated:YES]; //当前加载进度
    [self updateSlideValue:[LZBVideoPlayer shareInstance].progress]; //当前播放进度
}

#pragma mark - lazy
- (LZBPlayerBottomControlView *)bottomControllView
{
    if(_bottomControllView == nil)
    {
        _bottomControllView = [LZBPlayerBottomControlView new];
        [_bottomControllView.slider addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
        [_bottomControllView.lastButton addTarget:self action:@selector(lastButtonClick:) forControlEvents:UIControlEventTouchUpInside];
         [_bottomControllView.nextButton addTarget:self action:@selector(nextButtonClick:) forControlEvents:UIControlEventTouchUpInside];
         [_bottomControllView.playPasueButton addTarget:self action:@selector(playPasueButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _bottomControllView;
}

- (UIImage *)imageNamed:(NSString *)imageName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PlayerImage" ofType:@"bundle"];
    return [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", imageName]]];
}

- (void)dealloc
{
    [self removeLoadAnimation];
}

@end
